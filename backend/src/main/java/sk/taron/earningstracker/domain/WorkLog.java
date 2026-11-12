package sk.taron.earningstracker.domain;

import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Use {@link #create} for a new Work Log; the canonical constructor restores a stored one.
 */
public record WorkLog(UUID id, LocalDate day, WorkedTime workedTime, HourlyRate hourlyRate) {

    public static final long MAX_MINUTES = 24 * 60;

    public WorkLog {
        Objects.requireNonNull(id, "id must not be null");
        Objects.requireNonNull(day, "day must not be null");
        Objects.requireNonNull(workedTime, "workedTime must not be null");
        Objects.requireNonNull(hourlyRate, "hourlyRate must not be null");
        if (workedTime.minutes() == 0) {
            throw new IllegalArgumentException("Work log must record some worked time");
        }
        if (workedTime.minutes() > MAX_MINUTES) {
            throw new IllegalArgumentException("Work log must not exceed 24 hours: " + workedTime.minutes() + " min");
        }
    }

    public static WorkLog create(LocalDate day, WorkedTime workedTime, HourlyRate hourlyRate) {
        return new WorkLog(UUID.randomUUID(), day, workedTime, hourlyRate);
    }

    /** Corrects the day or worked time; the Hourly Rate stays the one the log was recorded with. */
    public WorkLog edit(LocalDate newDay, WorkedTime newWorkedTime) {
        return new WorkLog(id, newDay, newWorkedTime, hourlyRate);
    }

    public Money earnings() {
        return hourlyRate.earningsFor(workedTime);
    }
}
