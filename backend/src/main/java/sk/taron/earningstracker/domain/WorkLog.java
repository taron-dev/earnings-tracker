package sk.taron.earningstracker.domain;

import java.time.LocalDate;

public record WorkLog(LocalDate day, WorkedTime workedTime, HourlyRate hourlyRate) {

    public Money earnings() {
        return hourlyRate.earningsFor(workedTime);
    }
}
