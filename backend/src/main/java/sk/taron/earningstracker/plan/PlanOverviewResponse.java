package sk.taron.earningstracker.plan;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.jspecify.annotations.Nullable;

import sk.taron.earningstracker.api.MoneyDto;
import sk.taron.earningstracker.domain.CoverageState;
import sk.taron.earningstracker.domain.ItemCoverage;
import sk.taron.earningstracker.domain.NextMilestone;

/**
 * Items are referred to by their position in funding order, which stays unambiguous even
 * when two items have the same name and target.
 */
public record PlanOverviewResponse(
        UUID planId,
        EarningWindowDto window,
        int essentialsCount,
        MoneyDto earnings,
        boolean essentialsCovered,
        List<ItemCoverageDto> items,
        @Nullable NextMilestoneDto nextMilestone,
        MoneyDto unassignedEarnings) {

    public record ItemCoverageDto(int position, String name, MoneyDto target, MoneyDto funded,
                                  CoverageState state, boolean essential) {
    }

    /** {@code minutesNeeded}: worked time at the current rate to cover what is missing. */
    public record NextMilestoneDto(int position, MoneyDto missing, long minutesNeeded) {
    }

    static PlanOverviewResponse from(PlanOverview overview) {
        List<ItemCoverage> coverage = overview.coverage();
        int essentialsCount = overview.plan().essentialsCount();
        List<ItemCoverageDto> items = new ArrayList<>(coverage.size());
        for (int position = 0; position < coverage.size(); position++) {
            ItemCoverage item = coverage.get(position);
            items.add(new ItemCoverageDto(position, item.item().name(), MoneyDto.from(item.item().target()),
                    MoneyDto.from(item.funded()), item.state(), position < essentialsCount));
        }
        return new PlanOverviewResponse(
                overview.plan().id(),
                EarningWindowDto.from(overview.plan().window()),
                essentialsCount,
                MoneyDto.from(overview.earnings()),
                overview.essentialsCovered(),
                items,
                overview.nextMilestone().map(milestone -> nextMilestone(milestone, coverage)).orElse(null),
                MoneyDto.from(overview.unassignedEarnings()));
    }

    /** The next milestone is the first item in funding order that is not covered yet. */
    private static NextMilestoneDto nextMilestone(NextMilestone milestone, List<ItemCoverage> coverage) {
        int position = 0;
        while (coverage.get(position).state() == CoverageState.COVERED) {
            position++;
        }
        return new NextMilestoneDto(position, MoneyDto.from(milestone.missing()), milestone.timeNeeded().minutes());
    }
}
