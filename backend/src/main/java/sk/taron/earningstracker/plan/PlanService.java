package sk.taron.earningstracker.plan;

import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import sk.taron.earningstracker.api.NotFoundException;
import sk.taron.earningstracker.api.OverlappingPlanException;
import sk.taron.earningstracker.domain.EarningWindow;
import sk.taron.earningstracker.domain.Plan;
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
        EarningWindow window = plan.window();
        repository.findWindowsByUserId(userId).stream()
                .map(PlanWindow::toDomain)
                .filter(window::overlaps)
                .findFirst()
                .ifPresent(other -> {
                    throw new OverlappingPlanException("Earning window " + window.from() + " – " + window.to()
                            + " overlaps another plan (" + other.from() + " – " + other.to() + ")");
                });
        return mapper.toDomain(repository.save(mapper.from(plan, userId)));
    }

    @Transactional(readOnly = true)
    public Plan get(UUID userId, UUID id) {
        return repository.findByIdAndUserId(id, userId)
                .map(mapper::toDomain)
                .orElseThrow(() -> new NotFoundException("Plan not found"));
    }
}
