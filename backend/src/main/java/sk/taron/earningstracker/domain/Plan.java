package sk.taron.earningstracker.domain;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public record Plan(EarningWindow window, List<BudgetItem> items, int essentialsCount) {

    public Plan {
        Require.nonNull(window, "window");
        Require.nonNull(items, "items");
        items.forEach(item -> Require.nonNull(item, "budget item"));
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
        Require.nonNull(earnings, "earnings");
        Money essentialsTotal = new Money(BigDecimal.ZERO, earnings.currency());
        for (BudgetItem item : essentials()) {
            essentialsTotal = essentialsTotal.plus(item.target());
        }
        return earnings.isAtLeast(essentialsTotal);
    }

    public List<ItemCoverage> coverageFor(Money earnings) {
        Require.nonNull(earnings, "earnings");
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
