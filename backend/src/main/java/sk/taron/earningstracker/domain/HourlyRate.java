package sk.taron.earningstracker.domain;

import java.math.BigDecimal;
import java.math.RoundingMode;

public record HourlyRate(Money perHour) {

    private static final BigDecimal MINUTES_PER_HOUR = BigDecimal.valueOf(60);

    public HourlyRate {
        Require.nonNull(perHour, "perHour");
        if (perHour.amount().signum() == 0) {
            throw new IllegalArgumentException("Hourly rate must be positive");
        }
    }

    public Money earningsFor(WorkedTime workedTime) {
        Require.nonNull(workedTime, "workedTime");
        BigDecimal earned = perHour.amount()
                .multiply(BigDecimal.valueOf(workedTime.minutes()))
                .divide(MINUTES_PER_HOUR, perHour.currency().getDefaultFractionDigits(), RoundingMode.HALF_UP);
        return new Money(earned, perHour.currency());
    }

    public WorkedTime hoursToEarn(Money amount) {
        perHour.requireSameCurrency(amount);
        BigDecimal minutes = amount.amount()
                .multiply(MINUTES_PER_HOUR)
                .divide(perHour.amount(), 0, RoundingMode.CEILING);
        return new WorkedTime(minutes.longValueExact());
    }
}
