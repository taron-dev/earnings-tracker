package sk.taron.earningstracker.domain;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Currency;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Use {@link #create} for a new Plan; the canonical constructor restores a stored one.
 */
public record Plan(UUID id, EarningWindow window, List<BudgetItem> items, int essentialsCount) {

    public Plan {
        Objects.requireNonNull(id, "id must not be null");
        Objects.requireNonNull(window, "window must not be null");
        Objects.requireNonNull(items, "items must not be null");
        items.forEach(item -> Objects.requireNonNull(item, "budget item must not be null"));
        items = List.copyOf(items);
        if (items.stream().map(item -> item.target().currency()).distinct().count() > 1) {
            throw new IllegalArgumentException("Budget items of a plan must share one currency");
        }
        if (essentialsCount < 0 || essentialsCount > items.size()) {
            throw new IllegalArgumentException(
                    "Essentials count must be between 0 and " + items.size() + ": " + essentialsCount);
        }
    }

    public static Plan create(EarningWindow window, List<BudgetItem> items, int essentialsCount) {
        return new Plan(UUID.randomUUID(), window, items, essentialsCount);
    }

    public List<BudgetItem> essentials() {
        return items.subList(0, essentialsCount);
    }

    public List<BudgetItem> extras() {
        return items.subList(essentialsCount, items.size());
    }

    public boolean isEssentialsCoveredBy(Money earnings) {
        Objects.requireNonNull(earnings, "earnings must not be null");
        return earnings.isAtLeast(total(essentials(), earnings.currency()));
    }

    public Money unassignedEarnings(Money earnings) {
        Objects.requireNonNull(earnings, "earnings must not be null");
        return earnings.minusOrZero(total(items, earnings.currency()));
    }

    private static Money total(List<BudgetItem> items, Currency currency) {
        Money total = new Money(BigDecimal.ZERO, currency);
        for (BudgetItem item : items) {
            total = total.plus(item.target());
        }
        return total;
    }

    public Optional<NextMilestone> nextMilestone(Money earnings, HourlyRate currentRate) {
        Objects.requireNonNull(earnings, "earnings must not be null");
        Objects.requireNonNull(currentRate, "currentRate must not be null");
        earnings.requireSameCurrency(currentRate.perHour());
        return coverageFor(earnings).stream()
                .filter(coverage -> coverage.state() != CoverageState.COVERED)
                .findFirst()
                .map(coverage -> {
                    Money missing = coverage.item().target().minus(coverage.funded());
                    return new NextMilestone(coverage.item(), missing, currentRate.hoursToEarn(missing));
                });
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
