package sk.taron.earningstracker.plan;

import java.time.LocalDate;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import sk.taron.earningstracker.api.HourlyRateNotSetException;
import sk.taron.earningstracker.api.NotFoundException;
import sk.taron.earningstracker.domain.EarningWindow;
import sk.taron.earningstracker.domain.HourlyRate;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.domain.Plan;
import sk.taron.earningstracker.hourlyrate.HourlyRateService;
import sk.taron.earningstracker.persistence.PlanEntityMapper;
import sk.taron.earningstracker.persistence.PlanRepository;
import sk.taron.earningstracker.worklog.WorkLogService;

@Service
public class PlanOverviewService {

    private final PlanRepository planRepository;
    private final HourlyRateService hourlyRateService;
    private final WorkLogService workLogService;
    private final PlanEntityMapper mapper;

    PlanOverviewService(PlanRepository planRepository, HourlyRateService hourlyRateService,
                        WorkLogService workLogService, PlanEntityMapper mapper) {
        this.planRepository = planRepository;
        this.hourlyRateService = hourlyRateService;
        this.workLogService = workLogService;
        this.mapper = mapper;
    }

    /**
     * Overview of the plan whose Earning Window covers {@code date}. Earnings are counted in the
     * currency of the current rate, which the next milestone needs anyway.
     */
    @Transactional(readOnly = true)
    public PlanOverview overview(UUID userId, LocalDate date) {
        Plan plan = planRepository.findContaining(userId, date)
                .map(mapper::toDomain)
                .orElseThrow(() -> new NotFoundException("No plan covers " + date));
        HourlyRate currentRate = hourlyRateService.find(userId).orElseThrow(HourlyRateNotSetException::new);
        EarningWindow window = plan.window();
        Money earnings = window.earningsFrom(
                workLogService.list(userId, window.from(), window.to()), currentRate.perHour().currency());
        return new PlanOverview(
                plan,
                earnings,
                plan.coverageFor(earnings),
                plan.isEssentialsCoveredBy(earnings),
                plan.nextMilestone(earnings, currentRate),
                plan.unassignedEarnings(earnings));
    }
}
