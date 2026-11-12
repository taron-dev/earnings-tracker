package sk.taron.earningstracker.persistence;

import java.time.LocalDate;

import sk.taron.earningstracker.domain.EarningWindow;

/**
 * Only the Earning Window of a stored plan, loaded without its items.
 */
public record PlanWindow(LocalDate windowFrom, LocalDate windowTo) {

    public EarningWindow toDomain() {
        return new EarningWindow(windowFrom, windowTo);
    }
}
