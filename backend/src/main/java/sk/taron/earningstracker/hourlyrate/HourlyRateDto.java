package sk.taron.earningstracker.hourlyrate;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

import sk.taron.earningstracker.api.MoneyDto;
import sk.taron.earningstracker.domain.HourlyRate;

public record HourlyRateDto(@NotNull @Valid MoneyDto perHour) {

    static HourlyRateDto from(HourlyRate rate) {
        return new HourlyRateDto(MoneyDto.from(rate.perHour()));
    }

    HourlyRate toDomain() {
        return new HourlyRate(perHour.toDomain());
    }
}
