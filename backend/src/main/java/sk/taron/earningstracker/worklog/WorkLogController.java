package sk.taron.earningstracker.worklog;

import java.net.URI;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.format.annotation.DateTimeFormat.ISO;
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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import sk.taron.earningstracker.domain.WorkLog;

@RestController
@RequestMapping("/api/work-logs")
public class WorkLogController {

    private final WorkLogService workLogService;

    WorkLogController(WorkLogService workLogService) {
        this.workLogService = workLogService;
    }

    @PostMapping
    public ResponseEntity<WorkLogResponse> record(@AuthenticationPrincipal Jwt jwt,
                                                  @Valid @RequestBody WorkLogRequest request) {
        WorkLog recorded = workLogService.record(userId(jwt), request.day(), request.workedTime());
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(recorded.id())
                .toUri();
        return ResponseEntity.created(location).body(WorkLogResponse.from(recorded));
    }

    /** Work Logs dated from–to, both days included, newest first. */
    @GetMapping
    public List<WorkLogResponse> list(@AuthenticationPrincipal Jwt jwt,
                                      @RequestParam @DateTimeFormat(iso = ISO.DATE) LocalDate from,
                                      @RequestParam @DateTimeFormat(iso = ISO.DATE) LocalDate to) {
        return workLogService.list(userId(jwt), from, to).stream().map(WorkLogResponse::from).toList();
    }

    @GetMapping("/{id}")
    public WorkLogResponse get(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        return WorkLogResponse.from(workLogService.get(userId(jwt), id));
    }

    /** Changes day and worked time; the log keeps the Hourly Rate it was recorded with. */
    @PutMapping("/{id}")
    public WorkLogResponse edit(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id,
                                @Valid @RequestBody WorkLogRequest request) {
        return WorkLogResponse.from(workLogService.edit(userId(jwt), id, request.day(), request.workedTime()));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal Jwt jwt, @PathVariable UUID id) {
        workLogService.delete(userId(jwt), id);
    }

    private static UUID userId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
