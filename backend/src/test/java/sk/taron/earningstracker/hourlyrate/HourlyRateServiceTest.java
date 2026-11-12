package sk.taron.earningstracker.hourlyrate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.Mockito.mock;

import java.math.BigDecimal;
import java.util.Currency;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import sk.taron.earningstracker.api.NotFoundException;
import sk.taron.earningstracker.domain.HourlyRate;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.persistence.HourlyRateEntity;
import sk.taron.earningstracker.persistence.HourlyRateEntityMapper;
import sk.taron.earningstracker.persistence.HourlyRateRepository;

class HourlyRateServiceTest {

    private static final UUID USER_ID = UUID.fromString("7d3f1c2a-1b2c-4d5e-8f90-123456789abc");

    private final HourlyRateRepository repository = mock(HourlyRateRepository.class);
    private final HourlyRateEntityMapper mapper = new HourlyRateEntityMapper();
    private final HourlyRateService service = new HourlyRateService(repository, mapper);

    @Test
    void currentRateIsNotFoundBeforeUserSetsOne() {
        given(repository.findById(USER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> service.current(USER_ID))
                .isInstanceOf(NotFoundException.class)
                .hasMessage("Hourly rate is not set");
    }

    @Test
    void currentRateIsTheStoredOne() {
        given(repository.findById(USER_ID)).willReturn(Optional.of(mapper.from(eurPerHour("25"), USER_ID)));

        assertThat(service.current(USER_ID)).isEqualTo(eurPerHour("25"));
    }

    @Test
    void settingRateStoresItForUser() {
        given(repository.save(any(HourlyRateEntity.class))).willAnswer(invocation -> invocation.getArgument(0));

        HourlyRate saved = service.set(USER_ID, eurPerHour("32.50"));

        ArgumentCaptor<HourlyRateEntity> stored = ArgumentCaptor.forClass(HourlyRateEntity.class);
        then(repository).should().save(stored.capture());
        assertThat(stored.getValue().getUserId()).isEqualTo(USER_ID);
        assertThat(stored.getValue().getAmount()).isEqualByComparingTo("32.50");
        assertThat(saved).isEqualTo(eurPerHour("32.50"));
    }

    private static HourlyRate eurPerHour(String amount) {
        return new HourlyRate(new Money(new BigDecimal(amount), Currency.getInstance("EUR")));
    }
}
