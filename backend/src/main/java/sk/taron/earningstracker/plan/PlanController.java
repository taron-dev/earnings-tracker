package sk.taron.earningstracker.plan;

import java.net.URI;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import sk.taron.earningstracker.domain.Plan;

@RestController
@RequestMapping("/api/plans")
public class PlanController {

    private final PlanService planService;

    PlanController(PlanService planService) {
        this.planService = planService;
    }

    @PostMapping
    public ResponseEntity<PlanResponse> create(@AuthenticationPrincipal Jwt jwt,
                                               @Valid @RequestBody PlanRequest request) {
        Plan created = planService.create(userId(jwt), request.toNewPlan());
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(created.id())
                .toUri();
        return ResponseEntity.created(location).body(PlanResponse.from(created));
    }

    @GetMapping("/{id}")
    public PlanResponse get(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        return PlanResponse.from(planService.get(userId(jwt), id));
    }

    /** Replaces the whole plan; items are stored in the order sent. */
    @PutMapping("/{id}")
    public PlanResponse update(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id,
                               @Valid @RequestBody PlanRequest request) {
        return PlanResponse.from(planService.update(userId(jwt), request.toPlan(id)));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        planService.delete(userId(jwt), id);
    }

    private static UUID userId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
