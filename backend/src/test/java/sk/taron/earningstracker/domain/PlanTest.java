package sk.taron.earningstracker.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

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
    static final Plan PLAN = new Plan(OCTOBER, List.of(TAXES, MORTGAGE, VACATION), 2);

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
    void isNotChangedByLaterChangesToTheListItWasCreatedFrom() {
        List<BudgetItem> items = new ArrayList<>(List.of(TAXES));
        Plan plan = new Plan(OCTOBER, items, 1);

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
        assertThat(new Plan(OCTOBER, List.of(TAXES, MORTGAGE), 0).essentialsCount()).isZero();
        assertThat(new Plan(OCTOBER, List.of(TAXES, MORTGAGE), 2).essentialsCount()).isEqualTo(2);
        assertThat(new Plan(OCTOBER, List.of(), 0).essentialsCount()).isZero();
    }

    @Test
    void splitsItemsAtTheEssentialsLine() {
        assertThat(PLAN.essentials()).containsExactly(TAXES, MORTGAGE);
        assertThat(PLAN.extras()).containsExactly(VACATION);
    }

    @Test
    void hasOnlyExtrasWhenTheLineIsAtTheTopAndOnlyEssentialsWhenAtTheBottom() {
        Plan allExtras = new Plan(OCTOBER, List.of(TAXES, MORTGAGE), 0);
        Plan allEssentials = new Plan(OCTOBER, List.of(TAXES, MORTGAGE), 2);

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
        Plan allExtras = new Plan(OCTOBER, List.of(TAXES, MORTGAGE), 0);

        assertThat(allExtras.isEssentialsCoveredBy(eur("0"))).isTrue();
    }

    @Test
    void rejectsEssentialsLineOutsideTheFundingOrder() {
        assertThatIllegalArgumentException().isThrownBy(() -> new Plan(OCTOBER, List.of(TAXES, MORTGAGE), -1));
        assertThatIllegalArgumentException().isThrownBy(() -> new Plan(OCTOBER, List.of(TAXES, MORTGAGE), 3));
        assertThatIllegalArgumentException().isThrownBy(() -> new Plan(OCTOBER, List.of(), 1));
    }

    @Test
    void rejectsNull() {
        assertThatIllegalArgumentException().isThrownBy(() -> new BudgetItem(null, eur("100")));
        assertThatIllegalArgumentException().isThrownBy(() -> new BudgetItem("Odvody", null));
        assertThatIllegalArgumentException().isThrownBy(() -> new Plan(null, List.of(TAXES), 1));
        assertThatIllegalArgumentException().isThrownBy(() -> new Plan(OCTOBER, null, 0));
        assertThatIllegalArgumentException().isThrownBy(() -> new Plan(OCTOBER, Arrays.asList(TAXES, null), 1));
        assertThatIllegalArgumentException().isThrownBy(() -> PLAN.coverageFor(null));
        assertThatIllegalArgumentException().isThrownBy(() -> PLAN.isEssentialsCoveredBy(null));
    }
}
