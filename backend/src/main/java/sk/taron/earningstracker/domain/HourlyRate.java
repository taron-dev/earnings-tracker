package sk.taron.earningstracker.domain;

import java.math.BigDecimal;
import java.math.RoundingMode;

public record HourlyRate(Money amount) {

    private static final BigDecimal MINUTES_PER_HOUR = BigDecimal.valueOf(60);

    public HourlyRate {
        if (amount.amount().signum() == 0) {
            throw new IllegalArgumentException("Hourly rate must be positive");
        }
    }

    public Money earningsFor(Hours hours) {
        BigDecimal earned = amount.amount()
                .multiply(BigDecimal.valueOf(hours.minutes()))
                .divide(MINUTES_PER_HOUR, amount.currency().getDefaultFractionDigits(), RoundingMode.HALF_UP);
        return new Money(earned, amount.currency());
    }

    public Hours hoursToEarn(Money target) {
        if (!target.currency().equals(amount.currency())) {
            throw new IllegalArgumentException(
                    "Cannot earn " + target.currency() + " at a rate in " + amount.currency());
        }
        BigDecimal minutes = target.amount()
                .multiply(MINUTES_PER_HOUR)
                .divide(amount.amount(), 0, RoundingMode.CEILING);
        return new Hours(minutes.longValueExact());
    }
}
