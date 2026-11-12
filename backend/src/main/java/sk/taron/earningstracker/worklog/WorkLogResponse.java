package sk.taron.earningstracker.worklog;

import java.time.LocalDate;
import java.util.UUID;

import sk.taron.earningstracker.api.MoneyDto;
import sk.taron.earningstracker.domain.WorkLog;

public record WorkLogResponse(UUID id, LocalDate day, long minutes, MoneyDto hourlyRate, MoneyDto earnings) {

    static WorkLogResponse from(WorkLog workLog) {
        return new WorkLogResponse(
                workLog.id(),
                workLog.day(),
                workLog.workedTime().minutes(),
                MoneyDto.from(workLog.hourlyRate().perHour()),
                MoneyDto.from(workLog.earnings()));
    }
}
