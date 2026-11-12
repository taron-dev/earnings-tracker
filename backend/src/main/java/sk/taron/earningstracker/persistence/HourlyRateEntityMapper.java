package sk.taron.earningstracker.persistence;

import java.util.Currency;
import java.util.UUID;

import org.springframework.stereotype.Component;

import sk.taron.earningstracker.domain.HourlyRate;
import sk.taron.earningstracker.domain.Money;

@Component
public class HourlyRateEntityMapper implements EntityMapper<HourlyRate, HourlyRateEntity> {

    @Override
    public HourlyRate toDomain(HourlyRateEntity entity) {
        return new HourlyRate(new Money(entity.getAmount(), Currency.getInstance(entity.getCurrency())));
    }

    @Override
    public HourlyRateEntity from(HourlyRate domain, UUID userId) {
        Money perHour = domain.perHour();
        return new HourlyRateEntity(userId, perHour.amount(), perHour.currency().getCurrencyCode());
    }
}
