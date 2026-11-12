package sk.taron.earningstracker.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Currency;
import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.Test;

import sk.taron.earningstracker.domain.BudgetItem;
import sk.taron.earningstracker.domain.EarningWindow;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.domain.Plan;

class PlanEntityMapperTest {

    private static final UUID USER_ID = UUID.fromString("7d3f1c2a-1b2c-4d5e-8f90-123456789abc");
    private static final EarningWindow DECEMBER = new EarningWindow(LocalDate.of(2026, 12, 1), LocalDate.of(2026, 12, 31));
    private static final Plan PLAN = Plan.create(DECEMBER, List.of(
            new BudgetItem("Nájom", eur("600")),
            new BudgetItem("Odvody", eur("250.50")),
            new BudgetItem("Dovolenka", eur("300"))), 2);

    private final PlanEntityMapper mapper = new PlanEntityMapper();

    @Test
    void entityKeepsPlanAndOwner() {
        PlanEntity entity = mapper.from(PLAN, USER_ID);

        assertThat(entity.getId()).isEqualTo(PLAN.id());
        assertThat(entity.getUserId()).isEqualTo(USER_ID);
        assertThat(entity.getWindowFrom()).isEqualTo(LocalDate.of(2026, 12, 1));
        assertThat(entity.getWindowTo()).isEqualTo(LocalDate.of(2026, 12, 31));
        assertThat(entity.getEssentialsCount()).isEqualTo(2);
        assertThat(entity.getItems()).extracting(BudgetItemEmbeddable::getName)
                .containsExactly("Nájom", "Odvody", "Dovolenka");
    }

    @Test
    void entityMapsBackToSamePlanWithItemsInOrder() {
        assertThat(mapper.toDomain(mapper.from(PLAN, USER_ID))).isEqualTo(PLAN);
    }

    @Test
    void emptyPlanMapsBackToo() {
        Plan empty = Plan.create(DECEMBER, List.of(), 0);

        assertThat(mapper.toDomain(mapper.from(empty, USER_ID))).isEqualTo(empty);
    }

    private static Money eur(String amount) {
        return new Money(new BigDecimal(amount), Currency.getInstance("EUR"));
    }
}
