package sk.taron.earningstracker.hourlyrate;

import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.util.Currency;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import sk.taron.earningstracker.api.NotFoundException;
import sk.taron.earningstracker.domain.HourlyRate;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.security.SecurityConfig;

@WebMvcTest(controllers = HourlyRateController.class, properties = "SUPABASE_URL=http://localhost")
@Import(SecurityConfig.class)
class HourlyRateControllerTest {

    private static final UUID USER_ID = UUID.fromString("7d3f1c2a-1b2c-4d5e-8f90-123456789abc");

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    JwtDecoder jwtDecoder;

    @MockitoBean
    HourlyRateService hourlyRateService;

    @Test
    void returnsCurrentHourlyRateOfUser() throws Exception {
        given(hourlyRateService.current(USER_ID)).willReturn(eurPerHour("25"));

        mockMvc.perform(get("/api/hourly-rate").with(userToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.perHour.amount").value("25.00"))
                .andExpect(jsonPath("$.perHour.currency").value("EUR"));
    }

    @Test
    void answersNotFoundWhenUserHasNoHourlyRateYet() throws Exception {
        given(hourlyRateService.current(USER_ID)).willThrow(new NotFoundException("Hourly rate is not set"));

        mockMvc.perform(get("/api/hourly-rate").with(userToken()))
                .andExpect(status().isNotFound())
                .andExpect(content().contentType(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.detail").value("Hourly rate is not set"));
    }

    @Test
    void setsHourlyRateOfUser() throws Exception {
        given(hourlyRateService.set(USER_ID, eurPerHour("32.50"))).willReturn(eurPerHour("32.50"));

        mockMvc.perform(put("/api/hourly-rate").with(userToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"perHour": {"amount": "32.50", "currency": "EUR"}}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.perHour.amount").value("32.50"))
                .andExpect(jsonPath("$.perHour.currency").value("EUR"));
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "{\"perHour\": {\"amount\": \"25.00\", \"currency\": \"USD\"}}",
            "{\"perHour\": {\"amount\": \"25.125\", \"currency\": \"EUR\"}}",
            "{\"perHour\": {\"amount\": \"12345678901.00\", \"currency\": \"EUR\"}}",
            "{\"perHour\": {\"amount\": \"0.00\", \"currency\": \"EUR\"}}",
            "{\"perHour\": {\"amount\": \"-5.00\", \"currency\": \"EUR\"}}",
            "{\"perHour\": {\"currency\": \"EUR\"}}",
            "{}",
            "not json"
    })
    void rejectsInvalidHourlyRate(String body) throws Exception {
        mockMvc.perform(put("/api/hourly-rate").with(userToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentType(MediaType.APPLICATION_PROBLEM_JSON));

        then(hourlyRateService).shouldHaveNoInteractions();
    }

    @Test
    void rejectsRequestWithoutToken() throws Exception {
        mockMvc.perform(get("/api/hourly-rate"))
                .andExpect(status().isUnauthorized());
    }

    private static RequestPostProcessor userToken() {
        return jwt().jwt(token -> token.subject(USER_ID.toString()));
    }

    private static HourlyRate eurPerHour(String amount) {
        return new HourlyRate(new Money(new BigDecimal(amount), Currency.getInstance("EUR")));
    }
}
