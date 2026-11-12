package sk.taron.earningstracker.persistence;

import java.util.Currency;
import java.util.UUID;

import org.springframework.stereotype.Component;

import sk.taron.earningstracker.domain.HourlyRate;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.domain.WorkLog;
import sk.taron.earningstracker.domain.WorkedTime;

@Component
public class WorkLogEntityMapper implements EntityMapper<WorkLog, WorkLogEntity> {

    @Override
    public WorkLog toDomain(WorkLogEntity entity) {
        HourlyRate rate = new HourlyRate(
                new Money(entity.getRateAmount(), Currency.getInstance(entity.getRateCurrency())));
        return new WorkLog(entity.getId(), entity.getDay(), new WorkedTime(entity.getMinutes()), rate);
    }

    @Override
    public WorkLogEntity from(WorkLog domain, UUID userId) {
        Money rate = domain.hourlyRate().perHour();
        return new WorkLogEntity(domain.id(), userId, domain.day(), Math.toIntExact(domain.workedTime().minutes()),
                rate.amount(), rate.currency().getCurrencyCode());
    }
}
