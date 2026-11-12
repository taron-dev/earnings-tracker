package sk.taron.earningstracker.plan;

import java.util.List;
import java.util.UUID;

import sk.taron.earningstracker.domain.Plan;

public record PlanResponse(UUID id, EarningWindowDto window, List<BudgetItemDto> items, int essentialsCount) {

    static PlanResponse from(Plan plan) {
        return new PlanResponse(
                plan.id(),
                EarningWindowDto.from(plan.window()),
                plan.items().stream().map(BudgetItemDto::from).toList(),
                plan.essentialsCount());
    }
}
