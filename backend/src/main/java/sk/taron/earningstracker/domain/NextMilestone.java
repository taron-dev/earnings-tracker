    package sk.taron.earningstracker.domain;

import java.util.Objects;

public record NextMilestone(BudgetItem item, Money missing, WorkedTime timeNeeded) {

    public NextMilestone {
        Objects.requireNonNull(item, "item must not be null");
        Objects.requireNonNull(missing, "missing must not be null");
        Objects.requireNonNull(timeNeeded, "timeNeeded must not be null");
    }
}
