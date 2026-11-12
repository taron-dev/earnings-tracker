package sk.taron.earningstracker.plan;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import sk.taron.earningstracker.api.NotFoundException;
import sk.taron.earningstracker.api.OverlappingPlanException;
import sk.taron.earningstracker.domain.EarningWindow;
import sk.taron.earningstracker.domain.Plan;
import sk.taron.earningstracker.persistence.PlanEntity;
import sk.taron.earningstracker.persistence.PlanEntityMapper;
import sk.taron.earningstracker.persistence.PlanRepository;
import sk.taron.earningstracker.persistence.PlanWindow;

@Service
public class PlanService {

    private final PlanRepository repository;
    private final PlanEntityMapper mapper;

    PlanService(PlanRepository repository, PlanEntityMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    /**
     * Earning Windows of one user's plans must not overlap. The check lives only here (ADR 0004),
     * so two concurrent requests could still slip through.
     */
    @Transactional
    public Plan create(UUID userId, Plan plan) {
        requireNoOverlap(plan.window(), repository.findWindowsByUserId(userId));
        return save(plan, userId);
    }

    /**
     * Replaces the stored plan with the same id: window, essentials count and all items. Its
     * own current window is left out of the overlap check.
     */
    @Transactional
    public Plan update(UUID userId, Plan plan) {
        if (!repository.existsByIdAndUserId(plan.id(), userId)) {
            throw notFound();
        }
        requireNoOverlap(plan.window(), repository.findWindowsByUserIdAndIdNot(userId, plan.id()));
        return save(plan, userId);
    }

    @Transactional(readOnly = true)
    public Plan get(UUID userId, UUID id) {
        return mapper.toDomain(findEntity(userId, id));
    }

    /** Work Logs are not tied to the plan, so they stay and fund whichever plan covers them later. */
    @Transactional
    public void delete(UUID userId, UUID id) {
        repository.delete(findEntity(userId, id));
    }

    private static void requireNoOverlap(EarningWindow window, List<PlanWindow> others) {
        others.stream()
                .map(PlanWindow::toDomain)
                .filter(window::overlaps)
                .findFirst()
                .ifPresent(other -> {
                    throw new OverlappingPlanException("Earning window " + window.from() + " – " + window.to()
                            + " overlaps another plan (" + other.from() + " – " + other.to() + ")");
                });
    }

    /** Someone else's plan is reported as not found, so its existence is not revealed. */
    private PlanEntity findEntity(UUID userId, UUID id) {
        return repository.findByIdAndUserId(id, userId).orElseThrow(PlanService::notFound);
    }

    private static NotFoundException notFound() {
        return new NotFoundException("Plan not found");
    }

    private Plan save(Plan plan, UUID userId) {
        return mapper.toDomain(repository.save(mapper.from(plan, userId)));
    }
}
