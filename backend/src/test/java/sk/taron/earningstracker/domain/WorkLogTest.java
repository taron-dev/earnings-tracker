package sk.taron.earningstracker.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Currency;

import org.junit.jupiter.api.Test;

class WorkLogTest {

    static final LocalDate OCT_15 = LocalDate.of(2026, 10, 15);

    static Money eur(String amount) {
        return new Money(new BigDecimal(amount), Currency.getInstance("EUR"));
    }

    @Test
    void earnsWorkedTimeAtTheRateItWasRecordedWith() {
        WorkLog log = new WorkLog(OCT_15, WorkedTime.of(2, 30), new HourlyRate(eur("40")));

        assertThat(log.earnings()).isEqualTo(eur("100.00"));
    }

    @Test
    void rejectsNull() {
        WorkedTime workedTime = WorkedTime.of(1, 0);
        HourlyRate rate = new HourlyRate(eur("30"));

        assertThatIllegalArgumentException().isThrownBy(() -> new WorkLog(null, workedTime, rate));
        assertThatIllegalArgumentException().isThrownBy(() -> new WorkLog(OCT_15, null, rate));
        assertThatIllegalArgumentException().isThrownBy(() -> new WorkLog(OCT_15, workedTime, null));
    }
}
