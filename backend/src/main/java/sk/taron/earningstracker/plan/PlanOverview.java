package sk.taron.earningstracker.plan;

import java.util.List;
import java.util.Optional;

import sk.taron.earningstracker.domain.ItemCoverage;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.domain.NextMilestone;
import sk.taron.earningstracker.domain.Plan;

/**
 * Where a Plan stands: what its Earnings fund and what is still missing.
 */
public record PlanOverview(
        Plan plan,
        Money earnings,
        List<ItemCoverage> coverage,
        boolean essentialsCovered,
        Optional<NextMilestone> nextMilestone,
        Money unassignedEarnings) {
}
