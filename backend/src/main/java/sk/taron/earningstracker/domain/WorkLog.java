package sk.taron.earningstracker.domain;

import java.time.LocalDate;

public record WorkLog(LocalDate day, WorkedTime workedTime, HourlyRate hourlyRate) {

    public WorkLog {
        Require.nonNull(day, "day");
        Require.nonNull(workedTime, "workedTime");
        Require.nonNull(hourlyRate, "hourlyRate");
    }

    public Money earnings() {
        return hourlyRate.earningsFor(workedTime);
    }
}
