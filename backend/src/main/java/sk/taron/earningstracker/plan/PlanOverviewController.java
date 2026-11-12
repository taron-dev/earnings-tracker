package sk.taron.earningstracker.plan;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.format.annotation.DateTimeFormat.ISO;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class PlanOverviewController {

    private final PlanOverviewService planOverviewService;

    PlanOverviewController(PlanOverviewService planOverviewService) {
        this.planOverviewService = planOverviewService;
    }

    /**
     * Overview of the plan covering {@code date}. The client sends its local day, so the server
     * needs no time zone.
     */
    @GetMapping("/api/plans/current/overview")
    public PlanOverviewResponse overview(@AuthenticationPrincipal Jwt jwt,
                                         @RequestParam @DateTimeFormat(iso = ISO.DATE) LocalDate date) {
        return PlanOverviewResponse.from(planOverviewService.overview(userId(jwt), date));
    }

    /**
     * All plans with their coverage, newest first. The shape is the overview's, with
     * {@code nextMilestone} always {@code null}, so no hourly rate is needed.
     */
    @GetMapping("/api/plans")
    public List<PlanOverviewResponse> list(@AuthenticationPrincipal Jwt jwt) {
        return planOverviewService.list(userId(jwt)).stream()
                .map(PlanOverviewResponse::from)
                .toList();
    }

    private static UUID userId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
