package sk.taron.earningstracker.worklog;

import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.BDDMockito.willThrow;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Currency;
import java.util.List;
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

import sk.taron.earningstracker.api.HourlyRateNotSetException;
import sk.taron.earningstracker.api.NotFoundException;
import sk.taron.earningstracker.domain.HourlyRate;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.domain.WorkLog;
import sk.taron.earningstracker.domain.WorkedTime;
import sk.taron.earningstracker.security.SecurityConfig;

@WebMvcTest(controllers = WorkLogController.class, properties = "SUPABASE_URL=http://localhost")
@Import(SecurityConfig.class)
class WorkLogControllerTest {

    private static final UUID USER_ID = UUID.fromString("7d3f1c2a-1b2c-4d5e-8f90-123456789abc");
    private static final UUID LOG_ID = UUID.fromString("0b9c8d7e-6f5a-4b3c-9d2e-1f0a9b8c7d6e");
    private static final UUID OTHER_LOG_ID = UUID.fromString("1c2d3e4f-5a6b-4c7d-8e9f-0a1b2c3d4e5f");
    private static final LocalDate NOV_11 = LocalDate.of(2026, 11, 11);

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    JwtDecoder jwtDecoder;

    @MockitoBean
    WorkLogService workLogService;

    @Test
    void recordsWorkLogAndPointsToIt() throws Exception {
        given(workLogService.record(USER_ID, NOV_11, new WorkedTime(195)))
                .willReturn(new WorkLog(LOG_ID, NOV_11, new WorkedTime(195), eurPerHour("40")));

        mockMvc.perform(post("/api/work-logs").with(userToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"day": "2026-11-11", "minutes": 195}
                                """))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", "http://localhost/api/work-logs/" + LOG_ID))
                .andExpect(jsonPath("$.id").value(LOG_ID.toString()))
                .andExpect(jsonPath("$.day").value("2026-11-11"))
                .andExpect(jsonPath("$.minutes").value(195))
                .andExpect(jsonPath("$.hourlyRate.amount").value("40.00"))
                .andExpect(jsonPath("$.hourlyRate.currency").value("EUR"))
                .andExpect(jsonPath("$.earnings.amount").value("130.00"))
                .andExpect(jsonPath("$.earnings.currency").value("EUR"));
    }

    @Test
    void refusesToRecordBeforeHourlyRateIsSet() throws Exception {
        given(workLogService.record(USER_ID, NOV_11, new WorkedTime(60))).willThrow(new HourlyRateNotSetException());

        mockMvc.perform(post("/api/work-logs").with(userToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"day": "2026-11-11", "minutes": 60}
                                """))
                .andExpect(status().isConflict())
                .andExpect(content().contentType(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.type").value("/problems/hourly-rate-not-set"))
                .andExpect(jsonPath("$.detail").value("Set your hourly rate first"));
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "{\"minutes\": 60}",
            "{\"day\": \"2026-11-11\"}",
            "{\"day\": \"2026-11-11\", \"minutes\": 0}",
            "{\"day\": \"2026-11-11\", \"minutes\": 1441}",
            "{\"day\": \"11.11.2026\", \"minutes\": 60}",
            "not json"
    })
    void rejectsInvalidWorkLog(String body) throws Exception {
        mockMvc.perform(post("/api/work-logs").with(userToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentType(MediaType.APPLICATION_PROBLEM_JSON));

        then(workLogService).shouldHaveNoInteractions();
    }

    @Test
    void listsWorkLogsOfUserInRange() throws Exception {
        LocalDate from = LocalDate.of(2026, 11, 1);
        LocalDate to = LocalDate.of(2026, 11, 30);
        given(workLogService.list(USER_ID, from, to)).willReturn(List.of(
                new WorkLog(LOG_ID, NOV_11, new WorkedTime(60), eurPerHour("40")),
                new WorkLog(OTHER_LOG_ID, NOV_11.minusDays(1), new WorkedTime(30), eurPerHour("40"))));

        mockMvc.perform(get("/api/work-logs").param("from", "2026-11-01").param("to", "2026-11-30").with(userToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].id").value(LOG_ID.toString()))
                .andExpect(jsonPath("$[0].earnings.amount").value("40.00"))
                .andExpect(jsonPath("$[1].id").value(OTHER_LOG_ID.toString()))
                .andExpect(jsonPath("$[1].earnings.amount").value("20.00"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"/api/work-logs", "/api/work-logs?from=2026-11-01", "/api/work-logs?to=2026-11-30",
            "/api/work-logs?from=1.11.2026&to=2026-11-30"})
    void listingRequiresValidRange(String url) throws Exception {
        mockMvc.perform(get(url).with(userToken()))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentType(MediaType.APPLICATION_PROBLEM_JSON));
    }

    @Test
    void returnsOneWorkLog() throws Exception {
        given(workLogService.get(USER_ID, LOG_ID)).willReturn(new WorkLog(LOG_ID, NOV_11, new WorkedTime(90), eurPerHour("40")));

        mockMvc.perform(get("/api/work-logs/{id}", LOG_ID).with(userToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(LOG_ID.toString()))
                .andExpect(jsonPath("$.minutes").value(90))
                .andExpect(jsonPath("$.earnings.amount").value("60.00"));
    }

    @Test
    void editsWorkLog() throws Exception {
        given(workLogService.edit(USER_ID, LOG_ID, NOV_11, new WorkedTime(120)))
                .willReturn(new WorkLog(LOG_ID, NOV_11, new WorkedTime(120), eurPerHour("40")));

        mockMvc.perform(put("/api/work-logs/{id}", LOG_ID).with(userToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"day": "2026-11-11", "minutes": 120}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.minutes").value(120))
                .andExpect(jsonPath("$.earnings.amount").value("80.00"));
    }

    @Test
    void rejectsInvalidEdit() throws Exception {
        mockMvc.perform(put("/api/work-logs/{id}", LOG_ID).with(userToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"day": "2026-11-11", "minutes": 1441}
                                """))
                .andExpect(status().isBadRequest());

        then(workLogService).shouldHaveNoInteractions();
    }

    @Test
    void deletesWorkLog() throws Exception {
        mockMvc.perform(delete("/api/work-logs/{id}", LOG_ID).with(userToken()))
                .andExpect(status().isNoContent());

        then(workLogService).should().delete(USER_ID, LOG_ID);
    }

    @Test
    void answersNotFoundForUnknownOrForeignWorkLog() throws Exception {
        NotFoundException notFound = new NotFoundException("Work log not found");
        given(workLogService.get(USER_ID, LOG_ID)).willThrow(notFound);
        given(workLogService.edit(USER_ID, LOG_ID, NOV_11, new WorkedTime(60))).willThrow(notFound);
        willThrow(notFound).given(workLogService).delete(USER_ID, LOG_ID);

        mockMvc.perform(get("/api/work-logs/{id}", LOG_ID).with(userToken()))
                .andExpect(status().isNotFound());
        mockMvc.perform(put("/api/work-logs/{id}", LOG_ID).with(userToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"day": "2026-11-11", "minutes": 60}
                                """))
                .andExpect(status().isNotFound());
        mockMvc.perform(delete("/api/work-logs/{id}", LOG_ID).with(userToken()))
                .andExpect(status().isNotFound())
                .andExpect(content().contentType(MediaType.APPLICATION_PROBLEM_JSON));
    }

    @Test
    void rejectsRequestWithoutToken() throws Exception {
        mockMvc.perform(get("/api/work-logs/{id}", LOG_ID))
                .andExpect(status().isUnauthorized());
    }

    private static RequestPostProcessor userToken() {
        return jwt().jwt(token -> token.subject(USER_ID.toString()));
    }

    private static HourlyRate eurPerHour(String amount) {
        return new HourlyRate(new Money(new BigDecimal(amount), Currency.getInstance("EUR")));
    }
}
