package sk.taron.earningstracker.domain;

import java.util.ArrayList;
import java.util.List;

public record Plan(EarningWindow window, List<BudgetItem> items) {

    public Plan {
        Require.nonNull(window, "window");
        Require.nonNull(items, "items");
        items.forEach(item -> Require.nonNull(item, "budget item"));
        items = List.copyOf(items);
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
