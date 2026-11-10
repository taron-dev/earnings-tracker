package sk.taron.earningstracker.domain;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public record Plan(EarningWindow window, List<BudgetItem> items, int essentialsCount) {

    public Plan {
        Objects.requireNonNull(window, "window must not be null");
        Objects.requireNonNull(items, "items must not be null");
        items.forEach(item -> Objects.requireNonNull(item, "budget item must not be null"));
        items = List.copyOf(items);
        if (essentialsCount < 0 || essentialsCount > items.size()) {
            throw new IllegalArgumentException(
                    "Essentials count must be between 0 and " + items.size() + ": " + essentialsCount);
        }
    }

    public List<BudgetItem> essentials() {
        return items.subList(0, essentialsCount);
    }

    public List<BudgetItem> extras() {
        return items.subList(essentialsCount, items.size());
    }

    public boolean isEssentialsCoveredBy(Money earnings) {
        Objects.requireNonNull(earnings, "earnings must not be null");
        Money essentialsTotal = new Money(BigDecimal.ZERO, earnings.currency());
        for (BudgetItem item : essentials()) {
            essentialsTotal = essentialsTotal.plus(item.target());
        }
        return earnings.isAtLeast(essentialsTotal);
    }

    public List<ItemCoverage> coverageFor(Money earnings) {
        Objects.requireNonNull(earnings, "earnings must not be null");
        List<ItemCoverage> coverage = new ArrayList<>(items.size());
        Money remaining = earnings;
        for (BudgetItem item : items) {
            Money funded = remaining.isAtLeast(item.target()) ? item.target() : remaining;
            coverage.add(new ItemCoverage(item, funded));
            remaining = remaining.minus(funded);
        }
        return coverage;
    }
}
