package sk.taron.earningstracker.plan;

import java.net.URI;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
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

    private static UUID userId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
