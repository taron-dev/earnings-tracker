package sk.taron.earningstracker.hourlyrate;

import java.util.UUID;

import jakarta.validation.Valid;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/hourly-rate")
public class HourlyRateController {

    private final HourlyRateService hourlyRateService;

    HourlyRateController(HourlyRateService hourlyRateService) {
        this.hourlyRateService = hourlyRateService;
    }

    @GetMapping
    public HourlyRateDto current(@AuthenticationPrincipal Jwt jwt) {
        return HourlyRateDto.from(hourlyRateService.current(userId(jwt)));
    }

    @PutMapping
    public HourlyRateDto set(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody HourlyRateDto request) {
        return HourlyRateDto.from(hourlyRateService.set(userId(jwt), request.toDomain()));
    }

    private static UUID userId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
