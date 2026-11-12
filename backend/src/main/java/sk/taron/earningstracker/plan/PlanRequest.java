package sk.taron.earningstracker.plan;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

import sk.taron.earningstracker.domain.Plan;

/**
 * Items in funding order; the first {@code essentialsCount} of them are the essentials.
 */
public record PlanRequest(
        @NotNull @Valid EarningWindowDto window,
        @NotNull List<@NotNull @Valid BudgetItemDto> items,
        @NotNull Integer essentialsCount) {

    Plan toNewPlan() {
        return Plan.create(window.toDomain(), items.stream().map(BudgetItemDto::toDomain).toList(), essentialsCount);
    }
}
