package sk.taron.earningstracker.worklog;

import java.time.LocalDate;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import sk.taron.earningstracker.domain.WorkLog;
import sk.taron.earningstracker.domain.WorkedTime;

/**
 * Day and worked time of a Work Log; the Hourly Rate is filled in by the server.
 * The minute limits repeat the domain rule so the client learns which field is wrong.
 */
public record WorkLogRequest(
        @NotNull LocalDate day,
        @NotNull @Min(1) @Max(WorkLog.MAX_MINUTES) Integer minutes) {

    WorkedTime workedTime() {
        return new WorkedTime(minutes);
    }
}
