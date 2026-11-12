package sk.taron.earningstracker.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Currency;
import java.util.List;

import org.junit.jupiter.api.Test;

class PlanTest {

    static final EarningWindow OCTOBER = new EarningWindow(LocalDate.of(2026, 10, 1), LocalDate.of(2026, 10, 31));

    static Money eur(String amount) {
        return new Money(new BigDecimal(amount), Currency.getInstance("EUR"));
    }

    static final BudgetItem TAXES = new BudgetItem("Odvody", eur("100"));
    static final BudgetItem MORTGAGE = new BudgetItem("Hypotéka", eur("200"));
    static final BudgetItem VACATION = new BudgetItem("Dovolenka", eur("50"));
    static final Plan PLAN = Plan.create(OCTOBER, List.of(TAXES, MORTGAGE, VACATION), 2);

    @Test
    void leavesEveryItemUncoveredWithoutEarnings() {
        assertThat(PLAN.coverageFor(eur("0"))).containsExactly(
                new ItemCoverage(TAXES, eur("0")),
                new ItemCoverage(MORTGAGE, eur("0")),
                new ItemCoverage(VACATION, eur("0")));
        assertThat(PLAN.coverageFor(eur("0")))
                .extracting(ItemCoverage::state)
                .containsOnly(CoverageState.UNCOVERED);
    }

    @Test
    void fillsItemsInFundingOrderEachFullyBeforeTheNext() {
        List<ItemCoverage> coverage = PLAN.coverageFor(eur("150"));

        assertThat(coverage).containsExactly(
                new ItemCoverage(TAXES, eur("100")),
                new ItemCoverage(MORTGAGE, eur("50")),
                new ItemCoverage(VACATION, eur("0")));
        assertThat(coverage).extracting(ItemCoverage::state).containsExactly(
                CoverageState.COVERED, CoverageState.IN_PROGRESS, CoverageState.UNCOVERED);
    }

    @Test
    void earningsExactlyReachingAnItemCoverItAndLeaveTheNextUncovered() {
        assertThat(PLAN.coverageFor(eur("300"))).extracting(ItemCoverage::state).containsExactly(
                CoverageState.COVERED, CoverageState.COVERED, CoverageState.UNCOVERED);
    }

    @Test
    void anEmptyPlanHasNoCoverage() {
        assertThat(Plan.create(OCTOBER, List.of(), 0).coverageFor(eur("100"))).isEmpty();
    }

    @Test
    void rejectsItemsInDifferentCurrencies() {
        BudgetItem czkItem = new BudgetItem("Nájom", new Money(new BigDecimal("5000"), Currency.getInstance("CZK")));

        assertThatIllegalArgumentException().isThrownBy(() -> Plan.create(OCTOBER, List.of(TAXES, czkItem), 1));
    }

    @Test
    void isNotChangedByLaterChangesToTheListItWasCreatedFrom() {
        List<BudgetItem> items = new ArrayList<>(List.of(TAXES));
        Plan plan = Plan.create(OCTOBER, items, 1);

        items.add(MORTGAGE);

        assertThat(plan.items()).containsExactly(TAXES);
    }

    @Test
    void fundsNoItemBeyondItsTarget() {
        assertThat(PLAN.coverageFor(eur("1000"))).containsExactly(
                new ItemCoverage(TAXES, eur("100")),
                new ItemCoverage(MORTGAGE, eur("200")),
                new ItemCoverage(VACATION, eur("50")));
    }

    @Test
    void acceptsEssentialsLineFromTopToBottomOfTheFundingOrder() {
        assertThat(Plan.create(OCTOBER, List.of(TAXES, MORTGAGE), 0).essentialsCount()).isZero();
        assertThat(Plan.create(OCTOBER, List.of(TAXES, MORTGAGE), 2).essentialsCount()).isEqualTo(2);
        assertThat(Plan.create(OCTOBER, List.of(), 0).essentialsCount()).isZero();
    }

    @Test
    void splitsItemsAtTheEssentialsLine() {
        assertThat(PLAN.essentials()).containsExactly(TAXES, MORTGAGE);
        assertThat(PLAN.extras()).containsExactly(VACATION);
    }

    @Test
    void hasOnlyExtrasWhenTheLineIsAtTheTopAndOnlyEssentialsWhenAtTheBottom() {
        Plan allExtras = Plan.create(OCTOBER, List.of(TAXES, MORTGAGE), 0);
        Plan allEssentials = Plan.create(OCTOBER, List.of(TAXES, MORTGAGE), 2);

        assertThat(allExtras.essentials()).isEmpty();
        assertThat(allExtras.extras()).containsExactly(TAXES, MORTGAGE);
        assertThat(allEssentials.essentials()).containsExactly(TAXES, MORTGAGE);
        assertThat(allEssentials.extras()).isEmpty();
    }

    @Test
    void essentialsAreCoveredOnceEarningsReachTheirTotal() {
        assertThat(PLAN.isEssentialsCoveredBy(eur("299.99"))).isFalse();
        assertThat(PLAN.isEssentialsCoveredBy(eur("300"))).isTrue();
    }

    @Test
    void noEssentialsAreAlwaysCovered() {
        Plan allExtras = Plan.create(OCTOBER, List.of(TAXES, MORTGAGE), 0);

        assertThat(allExtras.isEssentialsCoveredBy(eur("0"))).isTrue();
    }

    @Test
    void rejectsEssentialsLineOutsideTheFundingOrder() {
        assertThatIllegalArgumentException().isThrownBy(() -> Plan.create(OCTOBER, List.of(TAXES, MORTGAGE), -1));
        assertThatIllegalArgumentException().isThrownBy(() -> Plan.create(OCTOBER, List.of(TAXES, MORTGAGE), 3));
        assertThatIllegalArgumentException().isThrownBy(() -> Plan.create(OCTOBER, List.of(), 1));
    }

    static final HourlyRate RATE = new HourlyRate(eur("40"));

    @Test
    void nextMilestoneIsTheFirstItemWhenNothingIsEarned() {
        assertThat(PLAN.nextMilestone(eur("0"), RATE))
                .contains(new NextMilestone(TAXES, eur("100"), WorkedTime.of(2, 30)));
    }

    @Test
    void nextMilestoneIsTheItemInProgressWithOnlyItsRemainderMissing() {
        assertThat(PLAN.nextMilestone(eur("150"), RATE))
                .contains(new NextMilestone(MORTGAGE, eur("150"), WorkedTime.of(3, 45)));
    }

    @Test
    void nextMilestoneSkipsAnItemCoveredExactly() {
        assertThat(PLAN.nextMilestone(eur("300"), RATE))
                .contains(new NextMilestone(VACATION, eur("50"), WorkedTime.of(1, 15)));
    }

    @Test
    void thereIsNoNextMilestoneOnceEveryItemIsCovered() {
        assertThat(PLAN.nextMilestone(eur("350"), RATE)).isEmpty();
        assertThat(PLAN.nextMilestone(eur("1000"), RATE)).isEmpty();
    }

    @Test
    void anEmptyPlanHasNoNextMilestone() {
        assertThat(Plan.create(OCTOBER, List.of(), 0).nextMilestone(eur("0"), RATE)).isEmpty();
    }

    @Test
    void nextMilestoneTimeAlwaysEarnsTheMissingAmountAndOneMinuteLessDoesNot() {
        HourlyRate oddRate = new HourlyRate(eur("37"));
        Plan plan = Plan.create(OCTOBER, List.of(new BudgetItem("Odvody", eur("10.01"))), 1);

        NextMilestone milestone = plan.nextMilestone(eur("0"), oddRate).orElseThrow();

        assertThat(milestone.timeNeeded()).isEqualTo(new WorkedTime(17));
        assertThat(oddRate.earningsFor(milestone.timeNeeded()).isAtLeast(milestone.missing())).isTrue();
        assertThat(oddRate.earningsFor(new WorkedTime(16)).isAtLeast(milestone.missing())).isFalse();
    }

    @Test
    void nextMilestoneRejectsRateInAnotherCurrencyEvenWhenEverythingIsCovered() {
        HourlyRate czkRate = new HourlyRate(new Money(new BigDecimal("1000"), Currency.getInstance("CZK")));

        assertThatIllegalArgumentException().isThrownBy(() -> PLAN.nextMilestone(eur("0"), czkRate));
        assertThatIllegalArgumentException().isThrownBy(() -> PLAN.nextMilestone(eur("1000"), czkRate));
    }

    @Test
    void nextMilestoneRejectsEarningsInAnotherCurrencyThanItems() {
        Money czkEarnings = new Money(new BigDecimal("0"), Currency.getInstance("CZK"));
        HourlyRate czkRate = new HourlyRate(new Money(new BigDecimal("1000"), Currency.getInstance("CZK")));

        assertThatIllegalArgumentException().isThrownBy(() -> PLAN.nextMilestone(czkEarnings, czkRate));
    }

    @Test
    void hasNoUnassignedEarningsUntilEarningsExceedAllItems() {
        assertThat(PLAN.unassignedEarnings(eur("0"))).isEqualTo(eur("0"));
        assertThat(PLAN.unassignedEarnings(eur("150"))).isEqualTo(eur("0"));
        assertThat(PLAN.unassignedEarnings(eur("350"))).isEqualTo(eur("0"));
    }

    @Test
    void unassignedEarningsAreEarningsBeyondAllItems() {
        assertThat(PLAN.unassignedEarnings(eur("350.01"))).isEqualTo(eur("0.01"));
        assertThat(PLAN.unassignedEarnings(eur("1000"))).isEqualTo(eur("650"));
    }

    @Test
    void anEmptyPlanLeavesAllEarningsUnassigned() {
        assertThat(Plan.create(OCTOBER, List.of(), 0).unassignedEarnings(eur("120.50"))).isEqualTo(eur("120.50"));
    }

    @Test
    void unassignedEarningsRejectEarningsInAnotherCurrencyThanItems() {
        Money czkEarnings = new Money(new BigDecimal("1000"), Currency.getInstance("CZK"));

        assertThatIllegalArgumentException().isThrownBy(() -> PLAN.unassignedEarnings(czkEarnings));
    }

    @Test
    void newPlansGetDistinctIds() {
        Plan first = Plan.create(OCTOBER, List.of(TAXES), 1);
        Plan second = Plan.create(OCTOBER, List.of(TAXES), 1);

        assertThat(first.id()).isNotEqualTo(second.id());
    }

    @Test
    @SuppressWarnings("DataFlowIssue")
    void rejectsNullId() {
        assertThatNullPointerException()
                .isThrownBy(() -> new Plan(null, OCTOBER, List.of(TAXES), 1))
                .withMessage("id must not be null");
    }

    @Test
    @SuppressWarnings("DataFlowIssue")
    void rejectsNull() {
        assertThatNullPointerException()
                .isThrownBy(() -> new BudgetItem(null, eur("100")))
                .withMessage("name must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> new BudgetItem("Odvody", null))
                .withMessage("target must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> Plan.create(null, List.of(TAXES), 1))
                .withMessage("window must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> Plan.create(OCTOBER, null, 0))
                .withMessage("items must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> Plan.create(OCTOBER, Arrays.asList(TAXES, null), 1))
                .withMessage("budget item must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> PLAN.coverageFor(null))
                .withMessage("earnings must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> PLAN.isEssentialsCoveredBy(null))
                .withMessage("earnings must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> PLAN.nextMilestone(null, RATE))
                .withMessage("earnings must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> PLAN.nextMilestone(eur("0"), null))
                .withMessage("currentRate must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> PLAN.unassignedEarnings(null))
                .withMessage("earnings must not be null");
    }
}
