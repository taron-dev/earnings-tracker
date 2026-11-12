package sk.taron.earningstracker.plan;

import static org.mockito.BDDMockito.given;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Currency;
import java.util.List;
import java.util.Optional;
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
import sk.taron.earningstracker.domain.BudgetItem;
import sk.taron.earningstracker.domain.EarningWindow;
import sk.taron.earningstracker.domain.ItemCoverage;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.domain.NextMilestone;
import sk.taron.earningstracker.domain.Plan;
import sk.taron.earningstracker.domain.WorkedTime;
import sk.taron.earningstracker.security.SecurityConfig;

@WebMvcTest(controllers = PlanOverviewController.class, properties = "SUPABASE_URL=http://localhost")
@Import(SecurityConfig.class)
class PlanOverviewControllerTest {

    private static final UUID USER_ID = UUID.fromString("7d3f1c2a-1b2c-4d5e-8f90-123456789abc");
    private static final LocalDate DEC_10 = LocalDate.of(2026, 12, 10);
    private static final EarningWindow DECEMBER = new EarningWindow(LocalDate.of(2026, 12, 1), LocalDate.of(2026, 12, 31));
    private static final BudgetItem SAVINGS = new BudgetItem("Rezerva", eur("100"));
    private static final BudgetItem VACATION = new BudgetItem("Dovolenka", eur("50"));
    /** Two identical items, so the next milestone must point to the second one by position. */
    private static final Plan PLAN = Plan.create(DECEMBER, List.of(SAVINGS, SAVINGS, VACATION), 2);

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    JwtDecoder jwtDecoder;

    @MockitoBean
    PlanOverviewService planOverviewService;

    @Test
    void returnsOverviewOfPlanCoveringTheDate() throws Exception {
        given(planOverviewService.overview(USER_ID, DEC_10)).willReturn(new PlanOverview(
                PLAN,
                eur("150"),
                List.of(new ItemCoverage(SAVINGS, eur("100")), new ItemCoverage(SAVINGS, eur("50")),
                        new ItemCoverage(VACATION, eur("0"))),
                false,
                Optional.of(new NextMilestone(SAVINGS, eur("50"), new WorkedTime(75))),
                eur("0")));

        mockMvc.perform(get("/api/plans/current/overview").param("date", "2026-12-10").with(userToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.planId").value(PLAN.id().toString()))
                .andExpect(jsonPath("$.window.from").value("2026-12-01"))
                .andExpect(jsonPath("$.window.to").value("2026-12-31"))
                .andExpect(jsonPath("$.essentialsCount").value(2))
                .andExpect(jsonPath("$.earnings.amount").value("150.00"))
                .andExpect(jsonPath("$.essentialsCovered").value(false))
                .andExpect(jsonPath("$.items.length()").value(3))
                .andExpect(jsonPath("$.items[0].position").value(0))
                .andExpect(jsonPath("$.items[0].name").value("Rezerva"))
                .andExpect(jsonPath("$.items[0].target.amount").value("100.00"))
                .andExpect(jsonPath("$.items[0].funded.amount").value("100.00"))
                .andExpect(jsonPath("$.items[0].state").value("COVERED"))
                .andExpect(jsonPath("$.items[0].essential").value(true))
                .andExpect(jsonPath("$.items[1].position").value(1))
                .andExpect(jsonPath("$.items[1].state").value("IN_PROGRESS"))
                .andExpect(jsonPath("$.items[1].essential").value(true))
                .andExpect(jsonPath("$.items[2].position").value(2))
                .andExpect(jsonPath("$.items[2].state").value("UNCOVERED"))
                .andExpect(jsonPath("$.items[2].essential").value(false))
                .andExpect(jsonPath("$.nextMilestone.position").value(1))
                .andExpect(jsonPath("$.nextMilestone.missing.amount").value("50.00"))
                .andExpect(jsonPath("$.nextMilestone.minutesNeeded").value(75))
                .andExpect(jsonPath("$.unassignedEarnings.amount").value("0.00"));
    }

    @Test
    void nextMilestoneIsNullWhenEverythingIsCovered() throws Exception {
        Plan plan = Plan.create(DECEMBER, List.of(VACATION), 0);
        given(planOverviewService.overview(USER_ID, DEC_10)).willReturn(new PlanOverview(
                plan, eur("80"), List.of(new ItemCoverage(VACATION, eur("50"))), true, Optional.empty(), eur("30")));

        mockMvc.perform(get("/api/plans/current/overview").param("date", "2026-12-10").with(userToken()))
                .andExpect(status().isOk())
                .andExpect(content().json("""
                        {"nextMilestone": null}
                        """))
                .andExpect(jsonPath("$.unassignedEarnings.amount").value("30.00"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"/api/plans/current/overview", "/api/plans/current/overview?date=10.12.2026"})
    void requiresValidDate(String url) throws Exception {
        mockMvc.perform(get(url).with(userToken()))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentType(MediaType.APPLICATION_PROBLEM_JSON));
    }

    @Test
    void answersNotFoundWhenNoPlanCoversTheDate() throws Exception {
        given(planOverviewService.overview(USER_ID, DEC_10)).willThrow(new NotFoundException("No plan covers 2026-12-10"));

        mockMvc.perform(get("/api/plans/current/overview").param("date", "2026-12-10").with(userToken()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.detail").value("No plan covers 2026-12-10"));
    }

    @Test
    void answersConflictWithoutHourlyRate() throws Exception {
        given(planOverviewService.overview(USER_ID, DEC_10)).willThrow(new HourlyRateNotSetException());

        mockMvc.perform(get("/api/plans/current/overview").param("date", "2026-12-10").with(userToken()))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.type").value("/problems/hourly-rate-not-set"));
    }

    @Test
    void listsPlansWithCoverageAndWithoutNextMilestone() throws Exception {
        Plan november = Plan.create(new EarningWindow(LocalDate.of(2026, 11, 1), LocalDate.of(2026, 11, 30)),
                List.of(VACATION), 0);
        given(planOverviewService.list(USER_ID)).willReturn(List.of(
                new PlanOverview(PLAN, eur("120"),
                        List.of(new ItemCoverage(SAVINGS, eur("100")), new ItemCoverage(SAVINGS, eur("20")),
                                new ItemCoverage(VACATION, eur("0"))),
                        false, Optional.empty(), eur("0")),
                new PlanOverview(november, eur("80"), List.of(new ItemCoverage(VACATION, eur("50"))), true,
                        Optional.empty(), eur("30"))));

        mockMvc.perform(get("/api/plans").with(userToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].planId").value(PLAN.id().toString()))
                .andExpect(jsonPath("$[0].window.from").value("2026-12-01"))
                .andExpect(jsonPath("$[0].essentialsCount").value(2))
                .andExpect(jsonPath("$[0].earnings.amount").value("120.00"))
                .andExpect(jsonPath("$[0].essentialsCovered").value(false))
                .andExpect(jsonPath("$[0].items.length()").value(3))
                .andExpect(jsonPath("$[0].items[1].funded.amount").value("20.00"))
                .andExpect(jsonPath("$[0].items[1].state").value("IN_PROGRESS"))
                .andExpect(jsonPath("$[0].items[2].essential").value(false))
                .andExpect(jsonPath("$[1].planId").value(november.id().toString()))
                .andExpect(jsonPath("$[1].essentialsCount").value(0))
                .andExpect(jsonPath("$[1].unassignedEarnings.amount").value("30.00"))
                .andExpect(content().json("""
                        [{"nextMilestone": null}, {"nextMilestone": null}]
                        """));
    }

    @Test
    void listsNoPlans() throws Exception {
        given(planOverviewService.list(USER_ID)).willReturn(List.of());

        mockMvc.perform(get("/api/plans").with(userToken()))
                .andExpect(status().isOk())
                .andExpect(content().json("[]"));
    }

    @ParameterizedTest
    @ValueSource(strings = {"/api/plans/current/overview?date=2026-12-10", "/api/plans"})
    void rejectsRequestWithoutToken(String url) throws Exception {
        mockMvc.perform(get(url))
                .andExpect(status().isUnauthorized());
    }

    private static RequestPostProcessor userToken() {
        return jwt().jwt(token -> token.subject(USER_ID.toString()));
    }

    private static Money eur(String amount) {
        return new Money(new BigDecimal(amount), Currency.getInstance("EUR"));
    }
}
