package sk.taron.earningstracker.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Currency;
import java.util.UUID;

import org.junit.jupiter.api.Test;

import sk.taron.earningstracker.domain.HourlyRate;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.domain.WorkLog;
import sk.taron.earningstracker.domain.WorkedTime;

class WorkLogEntityMapperTest {

    private static final UUID USER_ID = UUID.fromString("7d3f1c2a-1b2c-4d5e-8f90-123456789abc");
    private static final WorkLog WORK_LOG = WorkLog.create(
            LocalDate.of(2026, 11, 11), WorkedTime.of(3, 15),
            new HourlyRate(new Money(new BigDecimal("32.50"), Currency.getInstance("EUR"))));

    private final WorkLogEntityMapper mapper = new WorkLogEntityMapper();

    @Test
    void entityKeepsWorkLogAndOwner() {
        WorkLogEntity entity = mapper.from(WORK_LOG, USER_ID);

        assertThat(entity.getId()).isEqualTo(WORK_LOG.id());
        assertThat(entity.getUserId()).isEqualTo(USER_ID);
        assertThat(entity.getDay()).isEqualTo(LocalDate.of(2026, 11, 11));
        assertThat(entity.getMinutes()).isEqualTo(195);
        assertThat(entity.getRateAmount()).isEqualByComparingTo("32.50");
        assertThat(entity.getRateCurrency()).isEqualTo("EUR");
    }

    @Test
    void entityMapsBackToSameWorkLog() {
        assertThat(mapper.toDomain(mapper.from(WORK_LOG, USER_ID))).isEqualTo(WORK_LOG);
    }
}
