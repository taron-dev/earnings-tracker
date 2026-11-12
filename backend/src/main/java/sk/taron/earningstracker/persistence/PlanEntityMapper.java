package sk.taron.earningstracker.persistence;

import java.util.Currency;
import java.util.UUID;

import org.springframework.stereotype.Component;

import sk.taron.earningstracker.domain.BudgetItem;
import sk.taron.earningstracker.domain.EarningWindow;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.domain.Plan;

/**
 * Maps a Plan together with its Budget Items, which have no owner or identity of their own.
 */
@Component
public class PlanEntityMapper implements EntityMapper<Plan, PlanEntity> {

    @Override
    public Plan toDomain(PlanEntity entity) {
        return new Plan(
                entity.getId(),
                new EarningWindow(entity.getWindowFrom(), entity.getWindowTo()),
                entity.getItems().stream().map(PlanEntityMapper::toDomain).toList(),
                entity.getEssentialsCount());
    }

    @Override
    public PlanEntity from(Plan domain, UUID userId) {
        return new PlanEntity(
                domain.id(),
                userId,
                domain.window().from(),
                domain.window().to(),
                domain.essentialsCount(),
                domain.items().stream().map(PlanEntityMapper::from).toList());
    }

    private static BudgetItem toDomain(BudgetItemEmbeddable item) {
        return new BudgetItem(item.getName(),
                new Money(item.getTargetAmount(), Currency.getInstance(item.getTargetCurrency())));
    }

    private static BudgetItemEmbeddable from(BudgetItem item) {
        Money target = item.target();
        return new BudgetItemEmbeddable(item.name(), target.amount(), target.currency().getCurrencyCode());
    }
}
