package sk.taron.earningstracker.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import java.math.BigDecimal;
import java.util.Currency;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class HourlyRateTest {

    static Money eur(String amount) {
        return new Money(new BigDecimal(amount), Currency.getInstance("EUR"));
    }

    @Test
    void rejectsZeroRate() {
        assertThatIllegalArgumentException().isThrownBy(() -> new HourlyRate(eur("0")));
    }

    @Test
    void earningsAreRateTimesWorkedTime() {
        assertThat(new HourlyRate(eur("30")).earningsFor(Hours.of(7, 20))).isEqualTo(eur("220.00"));
    }

    @Test
    void earningsAreRoundedHalfUpToCents() {
        assertThat(new HourlyRate(eur("25")).earningsFor(Hours.of(0, 7))).isEqualTo(eur("2.92"));
        assertThat(new HourlyRate(eur("0.30")).earningsFor(Hours.of(0, 1))).isEqualTo(eur("0.01"));
    }

    @Test
    void hoursToEarnAreRoundedUpToWholeMinute() {
        assertThat(new HourlyRate(eur("33")).hoursToEarn(eur("100"))).isEqualTo(new Hours(182));
    }

    @Test
    void hoursToEarnAddNoExtraMinuteWhenExact() {
        assertThat(new HourlyRate(eur("30")).hoursToEarn(eur("60"))).isEqualTo(Hours.of(2, 0));
    }

    @Test
    void rejectsTargetInAnotherCurrency() {
        Money usd = new Money(new BigDecimal("100"), Currency.getInstance("USD"));

        assertThatIllegalArgumentException().isThrownBy(() -> new HourlyRate(eur("30")).hoursToEarn(usd));
    }

    @ParameterizedTest
    @CsvSource({"33, 100", "0.30, 0.01", "7.77, 1234.56", "45, 0", "29.99, 0.50"})
    void workingTheHoursToEarnAlwaysCoversTheTarget(String rate, String target) {
        HourlyRate hourlyRate = new HourlyRate(eur(rate));

        Money earned = hourlyRate.earningsFor(hourlyRate.hoursToEarn(eur(target)));

        assertThat(earned.isAtLeast(eur(target))).isTrue();
    }
}
