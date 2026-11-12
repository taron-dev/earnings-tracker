package sk.taron.earningstracker.plan;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import sk.taron.earningstracker.api.NotFoundException;
import sk.taron.earningstracker.api.OverlappingPlanException;
import sk.taron.earningstracker.domain.BudgetItem;
import sk.taron.earningstracker.domain.EarningWindow;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.domain.Plan;
import sk.taron.earningstracker.security.SecurityConfig;

@WebMvcTest(controllers = PlanController.class, properties = "SUPABASE_URL=http://localhost")
@Import(SecurityConfig.class)
class PlanControllerTest {

    private static final UUID USER_ID = UUID.fromString("7d3f1c2a-1b2c-4d5e-8f90-123456789abc");
    private static final EarningWindow DECEMBER = new EarningWindow(LocalDate.of(2026, 12, 1), LocalDate.of(2026, 12, 31));
    private static final Plan PLAN = Plan.create(DECEMBER, List.of(
            new BudgetItem("Nájom", eur("600")),
            new BudgetItem("Dovolenka", eur("300"))), 1);
    private static final String PLAN_JSON = """
            {
              "window": {"from": "2026-12-01", "to": "2026-12-31"},
              "items": [
                {"name": "Nájom", "target": {"amount": "600.00", "currency": "EUR"}},
                {"name": "Dovolenka", "target": {"amount": "300.00", "currency": "EUR"}}
              ],
              "essentialsCount": 1
            }
            """;

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    JwtDecoder jwtDecoder;

    @MockitoBean
    PlanService planService;

    @Test
    void createsPlanAndPointsToIt() throws Exception {
        given(planService.create(eq(USER_ID), any(Plan.class))).willReturn(PLAN);

        mockMvc.perform(post("/api/plans").with(userToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(PLAN_JSON))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", "http://localhost/api/plans/" + PLAN.id()))
                .andExpect(jsonPath("$.id").value(PLAN.id().toString()))
                .andExpect(jsonPath("$.window.from").value("2026-12-01"))
                .andExpect(jsonPath("$.window.to").value("2026-12-31"))
                .andExpect(jsonPath("$.items[0].name").value("Nájom"))
                .andExpect(jsonPath("$.items[0].target.amount").value("600.00"))
                .andExpect(jsonPath("$.items[1].name").value("Dovolenka"))
                .andExpect(jsonPath("$.essentialsCount").value(1));

        ArgumentCaptor<Plan> requested = ArgumentCaptor.forClass(Plan.class);
        then(planService).should().create(eq(USER_ID), requested.capture());
        assertThat(requested.getValue())
                .usingRecursiveComparison().ignoringFields("id").isEqualTo(PLAN);
    }

    @Test
    void refusesPlanOverlappingAnother() throws Exception {
        given(planService.create(eq(USER_ID), any(Plan.class)))
                .willThrow(new OverlappingPlanException("Earning window overlaps another plan"));

        mockMvc.perform(post("/api/plans").with(userToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(PLAN_JSON))
                .andExpect(status().isConflict())
                .andExpect(content().contentType(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.type").value("/problems/overlapping-plan"))
                .andExpect(jsonPath("$.detail").value("Earning window overlaps another plan"));
    }

    @ParameterizedTest
    @ValueSource(strings = {
            // no window
            "{\"items\": [], \"essentialsCount\": 0}",
            // window ends before it starts
            "{\"window\": {\"from\": \"2026-12-31\", \"to\": \"2026-12-01\"}, \"items\": [], \"essentialsCount\": 0}",
            // no items
            "{\"window\": {\"from\": \"2026-12-01\", \"to\": \"2026-12-31\"}, \"essentialsCount\": 0}",
            // no essentials count
            "{\"window\": {\"from\": \"2026-12-01\", \"to\": \"2026-12-31\"}, \"items\": []}",
            // essentials count beyond items
            "{\"window\": {\"from\": \"2026-12-01\", \"to\": \"2026-12-31\"}, \"items\": [], \"essentialsCount\": 1}",
            // blank item name
            "{\"window\": {\"from\": \"2026-12-01\", \"to\": \"2026-12-31\"}, \"items\": [{\"name\": \" \", \"target\": {\"amount\": \"10.00\", \"currency\": \"EUR\"}}], \"essentialsCount\": 0}",
            // other currency than EUR
            "{\"window\": {\"from\": \"2026-12-01\", \"to\": \"2026-12-31\"}, \"items\": [{\"name\": \"Nájom\", \"target\": {\"amount\": \"10.00\", \"currency\": \"USD\"}}], \"essentialsCount\": 0}",
            // zero target
            "{\"window\": {\"from\": \"2026-12-01\", \"to\": \"2026-12-31\"}, \"items\": [{\"name\": \"Nájom\", \"target\": {\"amount\": \"0.00\", \"currency\": \"EUR\"}}], \"essentialsCount\": 0}"
    })
    void rejectsInvalidPlan(String body) throws Exception {
        mockMvc.perform(post("/api/plans").with(userToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentType(MediaType.APPLICATION_PROBLEM_JSON));

        then(planService).shouldHaveNoInteractions();
    }

    @Test
    void returnsOnePlan() throws Exception {
        given(planService.get(USER_ID, PLAN.id())).willReturn(PLAN);

        mockMvc.perform(get("/api/plans/{id}", PLAN.id()).with(userToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(PLAN.id().toString()))
                .andExpect(jsonPath("$.items.length()").value(2))
                .andExpect(jsonPath("$.essentialsCount").value(1));
    }

    @Test
    void answersNotFoundForUnknownOrForeignPlan() throws Exception {
        given(planService.get(USER_ID, PLAN.id())).willThrow(new NotFoundException("Plan not found"));

        mockMvc.perform(get("/api/plans/{id}", PLAN.id()).with(userToken()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.detail").value("Plan not found"));
    }

    @Test
    void rejectsRequestWithoutToken() throws Exception {
        mockMvc.perform(get("/api/plans/{id}", PLAN.id()))
                .andExpect(status().isUnauthorized());
    }

    private static RequestPostProcessor userToken() {
        return jwt().jwt(token -> token.subject(USER_ID.toString()));
    }

    private static Money eur(String amount) {
        return new Money(new BigDecimal(amount), Currency.getInstance("EUR"));
    }
}
