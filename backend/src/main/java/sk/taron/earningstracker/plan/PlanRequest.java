package sk.taron.earningstracker.plan;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

import sk.taron.earningstracker.domain.BudgetItem;
import sk.taron.earningstracker.domain.Plan;

/**
 * Items in funding order; the first {@code essentialsCount} of them are the essentials.
 */
public record PlanRequest(
        @NotNull @Valid EarningWindowDto window,
        @NotNull List<@NotNull @Valid BudgetItemDto> items,
        @NotNull Integer essentialsCount) {

    Plan toNewPlan() {
        return Plan.create(window.toDomain(), budgetItems(), essentialsCount);
    }

    /** The plan with this id as the request describes it, replacing what is stored. */
    Plan toPlan(UUID id) {
        return new Plan(id, window.toDomain(), budgetItems(), essentialsCount);
    }

    private List<BudgetItem> budgetItems() {
        return items.stream().map(BudgetItemDto::toDomain).toList();
    }
}
