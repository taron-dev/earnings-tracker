package sk.taron.earningstracker.domain;

public record ItemCoverage(BudgetItem item, Money funded) {

    public CoverageState state() {
        if (funded.isAtLeast(item.target())) {
            return CoverageState.COVERED;
        }
        return funded.amount().signum() > 0 ? CoverageState.IN_PROGRESS : CoverageState.UNCOVERED;
    }
}
