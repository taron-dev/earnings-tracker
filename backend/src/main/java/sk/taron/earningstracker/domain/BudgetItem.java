package sk.taron.earningstracker.domain;

public record BudgetItem(String name, Money target) {

    public BudgetItem {
        Require.nonNull(name, "name");
        Require.nonNull(target, "target");
        if (name.isBlank()) {
            throw new IllegalArgumentException("Budget item name must not be blank");
        }
        if (target.amount().signum() == 0) {
            throw new IllegalArgumentException("Budget item target must be positive");
        }
    }
}
