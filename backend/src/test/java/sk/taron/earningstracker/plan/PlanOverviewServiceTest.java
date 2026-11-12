package sk.taron.earningstracker.plan;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.Currency;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.Test;

import sk.taron.earningstracker.api.HourlyRateNotSetException;
import sk.taron.earningstracker.api.NotFoundException;
import sk.taron.earningstracker.domain.BudgetItem;
import sk.taron.earningstracker.domain.CoverageState;
import sk.taron.earningstracker.domain.EarningWindow;
import sk.taron.earningstracker.domain.HourlyRate;
import sk.taron.earningstracker.domain.ItemCoverage;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.domain.NextMilestone;
import sk.taron.earningstracker.domain.Plan;
import sk.taron.earningstracker.domain.WorkLog;
import sk.taron.earningstracker.domain.WorkedTime;
import sk.taron.earningstracker.hourlyrate.HourlyRateService;
import sk.taron.earningstracker.persistence.PlanEntityMapper;
import sk.taron.earningstracker.persistence.PlanRepository;
import sk.taron.earningstracker.worklog.WorkLogService;

class PlanOverviewServiceTest {

    private static final UUID USER_ID = UUID.fromString("7d3f1c2a-1b2c-4d5e-8f90-123456789abc");
    private static final LocalDate DEC_1 = LocalDate.of(2026, 12, 1);
    private static final LocalDate DEC_10 = LocalDate.of(2026, 12, 10);
    private static final LocalDate DEC_31 = LocalDate.of(2026, 12, 31);
    private static final EarningWindow DECEMBER = new EarningWindow(DEC_1, DEC_31);
    private static final HourlyRate RATE = new HourlyRate(eur("40"));

    private static final BudgetItem TAXES = new BudgetItem("Odvody", eur("100"));
    private static final BudgetItem RENT = new BudgetItem("Nájom", eur("200"));
    private static final BudgetItem VACATION = new BudgetItem("Dovolenka", eur("50"));
    private static final Plan PLAN = Plan.create(DECEMBER, List.of(TAXES, RENT, VACATION), 2);

    private final PlanRepository planRepository = mock(PlanRepository.class);
    private final HourlyRateService hourlyRateService = mock(HourlyRateService.class);
    private final WorkLogService workLogService = mock(WorkLogService.class);
    private final PlanEntityMapper mapper = new PlanEntityMapper();
    private final PlanOverviewService service =
            new PlanOverviewService(planRepository, hourlyRateService, workLogService, mapper);

    @Test
    void overviewIsNotFoundWhenNoPlanCoversTheDate() {
        given(planRepository.findContaining(USER_ID, DEC_10)).willReturn(Optional.empty());

        assertThatThrownBy(() -> service.overview(USER_ID, DEC_10))
                .isInstanceOf(NotFoundException.class)
                .hasMessage("No plan covers 2026-12-10");
    }

    @Test
    void overviewNeedsHourlyRate() {
        givenPlan(PLAN);
        given(hourlyRateService.find(USER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> service.overview(USER_ID, DEC_10)).isInstanceOf(HourlyRateNotSetException.class);
    }

    @Test
    void overviewFundsItemsFromWorkLogsInTheWindow() {
        givenPlan(PLAN);
        given(hourlyRateService.find(USER_ID)).willReturn(Optional.of(RATE));
        givenWorkLogs(WorkedTime.of(2, 0), WorkedTime.of(1, 30));

        PlanOverview overview = service.overview(USER_ID, DEC_10);

        assertThat(overview.plan()).isEqualTo(PLAN);
        assertThat(overview.earnings()).isEqualTo(eur("140.00"));
        assertThat(overview.coverage()).containsExactly(
                new ItemCoverage(TAXES, eur("100")),
                new ItemCoverage(RENT, eur("40")),
                new ItemCoverage(VACATION, eur("0")));
        assertThat(overview.essentialsCovered()).isFalse();
        assertThat(overview.nextMilestone()).contains(new NextMilestone(RENT, eur("160"), new WorkedTime(240)));
        assertThat(overview.unassignedEarnings()).isEqualTo(eur("0"));
    }

    @Test
    void fullyFundedPlanHasNoNextMilestoneAndUnassignedEarnings() {
        givenPlan(PLAN);
        given(hourlyRateService.find(USER_ID)).willReturn(Optional.of(RATE));
        givenWorkLogs(WorkedTime.of(10, 0));

        PlanOverview overview = service.overview(USER_ID, DEC_10);

        assertThat(overview.coverage()).extracting(ItemCoverage::state).containsOnly(CoverageState.COVERED);
        assertThat(overview.essentialsCovered()).isTrue();
        assertThat(overview.nextMilestone()).isEmpty();
        assertThat(overview.unassignedEarnings()).isEqualTo(eur("50"));
    }

    @Test
    void emptyPlanLeavesAllEarningsUnassigned() {
        Plan empty = Plan.create(DECEMBER, List.of(), 0);
        givenPlan(empty);
        given(hourlyRateService.find(USER_ID)).willReturn(Optional.of(RATE));
        givenWorkLogs(WorkedTime.of(1, 0));

        PlanOverview overview = service.overview(USER_ID, DEC_10);

        assertThat(overview.coverage()).isEmpty();
        assertThat(overview.nextMilestone()).isEmpty();
        assertThat(overview.unassignedEarnings()).isEqualTo(eur("40"));
    }

    @Test
    void listIsEmptyWithoutPlans() {
        given(planRepository.findByUserIdOrderByWindowFromDesc(USER_ID)).willReturn(List.of());

        assertThat(service.list(USER_ID)).isEmpty();
        verifyNoInteractions(workLogService);
    }

    @Test
    void listFundsEachPlanFromWorkLogsInItsOwnWindowWithoutHourlyRate() {
        LocalDate nov1 = LocalDate.of(2026, 11, 1);
        LocalDate nov20 = LocalDate.of(2026, 11, 20);
        Plan november = Plan.create(new EarningWindow(nov1, nov20), List.of(TAXES), 1);
        given(planRepository.findByUserIdOrderByWindowFromDesc(USER_ID))
                .willReturn(List.of(mapper.from(PLAN, USER_ID), mapper.from(november, USER_ID)));
        given(workLogService.list(USER_ID, nov1, DEC_31)).willReturn(List.of(
                WorkLog.create(DEC_10, WorkedTime.of(2, 0), RATE),
                WorkLog.create(LocalDate.of(2026, 11, 25), WorkedTime.of(5, 0), RATE),
                WorkLog.create(LocalDate.of(2026, 11, 5), WorkedTime.of(3, 0), RATE)));

        List<PlanOverview> overviews = service.list(USER_ID);

        assertThat(overviews).extracting(PlanOverview::plan).containsExactly(PLAN, november);
        PlanOverview december = overviews.get(0);
        assertThat(december.earnings()).isEqualTo(eur("80.00"));
        assertThat(december.coverage()).containsExactly(
                new ItemCoverage(TAXES, eur("80")),
                new ItemCoverage(RENT, eur("0")),
                new ItemCoverage(VACATION, eur("0")));
        assertThat(december.essentialsCovered()).isFalse();
        assertThat(december.nextMilestone()).isEmpty();
        PlanOverview past = overviews.get(1);
        assertThat(past.earnings()).isEqualTo(eur("120.00"));
        assertThat(past.essentialsCovered()).isTrue();
        assertThat(past.nextMilestone()).isEmpty();
        assertThat(past.unassignedEarnings()).isEqualTo(eur("20"));
        verifyNoInteractions(hourlyRateService);
    }

    @Test
    void listCountsEmptyPlanInEuro() {
        Plan empty = Plan.create(DECEMBER, List.of(), 0);
        given(planRepository.findByUserIdOrderByWindowFromDesc(USER_ID)).willReturn(List.of(mapper.from(empty, USER_ID)));
        given(workLogService.list(USER_ID, DEC_1, DEC_31)).willReturn(List.of());

        PlanOverview overview = service.list(USER_ID).getFirst();

        assertThat(overview.earnings()).isEqualTo(eur("0"));
        assertThat(overview.unassignedEarnings()).isEqualTo(eur("0"));
    }

    private void givenPlan(Plan plan) {
        given(planRepository.findContaining(USER_ID, DEC_10)).willReturn(Optional.of(mapper.from(plan, USER_ID)));
    }

    private void givenWorkLogs(WorkedTime... times) {
        List<WorkLog> logs = Arrays.stream(times).map(time -> WorkLog.create(DEC_10, time, RATE)).toList();
        given(workLogService.list(USER_ID, DEC_1, DEC_31)).willReturn(logs);
    }

    private static Money eur(String amount) {
        return new Money(new BigDecimal(amount), Currency.getInstance("EUR"));
    }
}
