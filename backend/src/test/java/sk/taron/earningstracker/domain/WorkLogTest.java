package sk.taron.earningstracker.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatNullPointerException;

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
    @SuppressWarnings("DataFlowIssue")
    void rejectsNull() {
        WorkedTime workedTime = WorkedTime.of(1, 0);
        HourlyRate rate = new HourlyRate(eur("30"));

        assertThatNullPointerException()
                .isThrownBy(() -> new WorkLog(null, workedTime, rate))
                .withMessage("day must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> new WorkLog(OCT_15, null, rate))
                .withMessage("workedTime must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> new WorkLog(OCT_15, workedTime, null))
                .withMessage("hourlyRate must not be null");
    }
}
