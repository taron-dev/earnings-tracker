package sk.taron.earningstracker.domain;

import java.util.Objects;

public record BudgetItem(String name, Money target) {

    public BudgetItem {
        Objects.requireNonNull(name, "name must not be null");
        Objects.requireNonNull(target, "target must not be null");
        if (name.isBlank()) {
            throw new IllegalArgumentException("Budget item name must not be blank");
        }
        if (target.amount().signum() == 0) {
            throw new IllegalArgumentException("Budget item target must be positive");
        }
    }
}
