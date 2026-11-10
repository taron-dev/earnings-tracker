package sk.taron.earningstracker.domain;

import java.time.LocalDate;
import java.util.Objects;

public record WorkLog(LocalDate day, WorkedTime workedTime, HourlyRate hourlyRate) {

    public WorkLog {
        Objects.requireNonNull(day, "day must not be null");
        Objects.requireNonNull(workedTime, "workedTime must not be null");
        Objects.requireNonNull(hourlyRate, "hourlyRate must not be null");
        if (workedTime.minutes() == 0) {
            throw new IllegalArgumentException("Work log must record some worked time");
        }
    }

    public Money earnings() {
        return hourlyRate.earningsFor(workedTime);
    }
}
