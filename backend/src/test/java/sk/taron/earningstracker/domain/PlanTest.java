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
    static final Plan PLAN = new Plan(OCTOBER, List.of(TAXES, MORTGAGE, VACATION));

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
        Plan plan = new Plan(OCTOBER, items);

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
    void rejectsNull() {
        assertThatIllegalArgumentException().isThrownBy(() -> new BudgetItem(null, eur("100")));
        assertThatIllegalArgumentException().isThrownBy(() -> new BudgetItem("Odvody", null));
        assertThatIllegalArgumentException().isThrownBy(() -> new Plan(null, List.of(TAXES)));
        assertThatIllegalArgumentException().isThrownBy(() -> new Plan(OCTOBER, null));
        assertThatIllegalArgumentException().isThrownBy(() -> new Plan(OCTOBER, Arrays.asList(TAXES, null)));
        assertThatIllegalArgumentException().isThrownBy(() -> PLAN.coverageFor(null));
    }
}
