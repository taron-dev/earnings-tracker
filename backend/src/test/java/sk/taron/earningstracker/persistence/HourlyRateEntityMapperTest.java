package sk.taron.earningstracker.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.Currency;
import java.util.UUID;

import org.junit.jupiter.api.Test;

import sk.taron.earningstracker.domain.HourlyRate;
import sk.taron.earningstracker.domain.Money;

class HourlyRateEntityMapperTest {

    private static final UUID USER_ID = UUID.fromString("7d3f1c2a-1b2c-4d5e-8f90-123456789abc");

    private final HourlyRateEntityMapper mapper = new HourlyRateEntityMapper();

    @Test
    void entityKeepsRateAndOwner() {
        HourlyRateEntity entity = mapper.from(eurPerHour("32.50"), USER_ID);

        assertThat(entity.getUserId()).isEqualTo(USER_ID);
        assertThat(entity.getAmount()).isEqualByComparingTo("32.50");
        assertThat(entity.getCurrency()).isEqualTo("EUR");
    }

    @Test
    void entityMapsBackToSameRate() {
        assertThat(mapper.toDomain(mapper.from(eurPerHour("32.50"), USER_ID))).isEqualTo(eurPerHour("32.50"));
    }

    private static HourlyRate eurPerHour(String amount) {
        return new HourlyRate(new Money(new BigDecimal(amount), Currency.getInstance("EUR")));
    }
}
