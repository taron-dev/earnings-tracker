package sk.taron.earningstracker.plan;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Currency;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import sk.taron.earningstracker.api.NotFoundException;
import sk.taron.earningstracker.api.OverlappingPlanException;
import sk.taron.earningstracker.domain.BudgetItem;
import sk.taron.earningstracker.domain.EarningWindow;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.domain.Plan;
import sk.taron.earningstracker.persistence.PlanEntity;
import sk.taron.earningstracker.persistence.PlanEntityMapper;
import sk.taron.earningstracker.persistence.PlanRepository;
import sk.taron.earningstracker.persistence.PlanWindow;

class PlanServiceTest {

    private static final UUID USER_ID = UUID.fromString("7d3f1c2a-1b2c-4d5e-8f90-123456789abc");
    private static final LocalDate DEC_1 = LocalDate.of(2026, 12, 1);
    private static final LocalDate DEC_31 = LocalDate.of(2026, 12, 31);
    private static final Plan DECEMBER_PLAN = Plan.create(
            new EarningWindow(DEC_1, DEC_31), List.of(new BudgetItem("Nájom", eur("600"))), 1);

    private final PlanRepository repository = mock(PlanRepository.class);
    private final PlanEntityMapper mapper = new PlanEntityMapper();
    private final PlanService service = new PlanService(repository, mapper);

    @Test
    void creatingStoresPlanForUser() {
        given(repository.findWindowsByUserId(USER_ID)).willReturn(List.of());
        given(repository.save(any(PlanEntity.class))).willAnswer(invocation -> invocation.getArgument(0));

        Plan created = service.create(USER_ID, DECEMBER_PLAN);

        assertThat(created).isEqualTo(DECEMBER_PLAN);
        ArgumentCaptor<PlanEntity> stored = ArgumentCaptor.forClass(PlanEntity.class);
        then(repository).should().save(stored.capture());
        assertThat(stored.getValue().getUserId()).isEqualTo(USER_ID);
        assertThat(stored.getValue().getId()).isEqualTo(DECEMBER_PLAN.id());
    }

    @Test
    void creatingPlanOverlappingAnotherIsRefused() {
        given(repository.findWindowsByUserId(USER_ID))
                .willReturn(List.of(new PlanWindow(LocalDate.of(2026, 11, 15), DEC_1)));

        assertThatThrownBy(() -> service.create(USER_ID, DECEMBER_PLAN))
                .isInstanceOf(OverlappingPlanException.class)
                .hasMessage("Earning window 2026-12-01 – 2026-12-31 overlaps another plan (2026-11-15 – 2026-12-01)");
        then(repository).should(never()).save(any(PlanEntity.class));
    }

    @Test
    void creatingPlanRightAfterAnotherIsAllowed() {
        given(repository.findWindowsByUserId(USER_ID))
                .willReturn(List.of(new PlanWindow(LocalDate.of(2026, 11, 1), LocalDate.of(2026, 11, 30))));
        given(repository.save(any(PlanEntity.class))).willAnswer(invocation -> invocation.getArgument(0));

        assertThat(service.create(USER_ID, DECEMBER_PLAN)).isEqualTo(DECEMBER_PLAN);
    }

    @Test
    void gettingReturnsOwnPlan() {
        given(repository.findByIdAndUserId(DECEMBER_PLAN.id(), USER_ID))
                .willReturn(Optional.of(mapper.from(DECEMBER_PLAN, USER_ID)));

        assertThat(service.get(USER_ID, DECEMBER_PLAN.id())).isEqualTo(DECEMBER_PLAN);
    }

    @Test
    void gettingUnknownOrForeignPlanIsNotFound() {
        UUID id = UUID.randomUUID();
        given(repository.findByIdAndUserId(id, USER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> service.get(USER_ID, id))
                .isInstanceOf(NotFoundException.class)
                .hasMessage("Plan not found");
    }

    @Test
    void updatingReplacesOwnPlanAndChecksOverlapWithOtherPlansOnly() {
        Plan edited = new Plan(DECEMBER_PLAN.id(), new EarningWindow(DEC_1, LocalDate.of(2027, 1, 15)),
                List.of(new BudgetItem("Dovolenka", eur("300")), new BudgetItem("Nájom", eur("650"))), 2);
        given(repository.existsByIdAndUserId(DECEMBER_PLAN.id(), USER_ID)).willReturn(true);
        given(repository.findWindowsByUserIdAndIdNot(USER_ID, DECEMBER_PLAN.id()))
                .willReturn(List.of(new PlanWindow(LocalDate.of(2026, 11, 1), LocalDate.of(2026, 11, 30))));
        given(repository.save(any(PlanEntity.class))).willAnswer(invocation -> invocation.getArgument(0));

        Plan updated = service.update(USER_ID, edited);

        assertThat(updated).isEqualTo(edited);
        ArgumentCaptor<PlanEntity> stored = ArgumentCaptor.forClass(PlanEntity.class);
        then(repository).should().save(stored.capture());
        assertThat(stored.getValue().getId()).isEqualTo(DECEMBER_PLAN.id());
        assertThat(stored.getValue().getUserId()).isEqualTo(USER_ID);
        then(repository).should(never()).findWindowsByUserId(any());
    }

    @Test
    void updatingPlanSoItOverlapsAnotherIsRefused() {
        given(repository.existsByIdAndUserId(DECEMBER_PLAN.id(), USER_ID)).willReturn(true);
        given(repository.findWindowsByUserIdAndIdNot(USER_ID, DECEMBER_PLAN.id()))
                .willReturn(List.of(new PlanWindow(DEC_31, LocalDate.of(2027, 1, 31))));

        assertThatThrownBy(() -> service.update(USER_ID, DECEMBER_PLAN))
                .isInstanceOf(OverlappingPlanException.class)
                .hasMessage("Earning window 2026-12-01 – 2026-12-31 overlaps another plan (2026-12-31 – 2027-01-31)");
        then(repository).should(never()).save(any(PlanEntity.class));
    }

    @Test
    void updatingUnknownOrForeignPlanIsNotFound() {
        given(repository.existsByIdAndUserId(DECEMBER_PLAN.id(), USER_ID)).willReturn(false);

        assertThatThrownBy(() -> service.update(USER_ID, DECEMBER_PLAN))
                .isInstanceOf(NotFoundException.class)
                .hasMessage("Plan not found");
        then(repository).should(never()).save(any(PlanEntity.class));
    }

    @Test
    void deletingRemovesOwnPlan() {
        PlanEntity entity = mapper.from(DECEMBER_PLAN, USER_ID);
        given(repository.findByIdAndUserId(DECEMBER_PLAN.id(), USER_ID)).willReturn(Optional.of(entity));

        service.delete(USER_ID, DECEMBER_PLAN.id());

        then(repository).should().delete(entity);
    }

    @Test
    void deletingUnknownOrForeignPlanIsNotFound() {
        given(repository.findByIdAndUserId(DECEMBER_PLAN.id(), USER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> service.delete(USER_ID, DECEMBER_PLAN.id()))
                .isInstanceOf(NotFoundException.class)
                .hasMessage("Plan not found");
        then(repository).should(never()).delete(any(PlanEntity.class));
    }

    private static Money eur(String amount) {
        return new Money(new BigDecimal(amount), Currency.getInstance("EUR"));
    }
}
