package sk.taron.earningstracker.hello;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Walking-skeleton endpoint: proves the whole path Flutter → Supabase token → Spring works.
 */
@RestController
@RequestMapping("/api/hello")
public class HelloController {

    @GetMapping
    public HelloResponse hello(@AuthenticationPrincipal Jwt jwt) {
        String email = jwt.getClaimAsString("email");
        return new HelloResponse(jwt.getSubject(), "Hello, " + (email != null ? email : "user"));
    }

    public record HelloResponse(String userId, String message) {}
}
