package sk.taron.earningstracker.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;
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
        WorkLog log = WorkLog.create(OCT_15, WorkedTime.of(2, 30), new HourlyRate(eur("40")));

        assertThat(log.earnings()).isEqualTo(eur("100.00"));
    }

    @Test
    void rejectsZeroWorkedTime() {
        assertThatIllegalArgumentException()
                .isThrownBy(() -> WorkLog.create(OCT_15, new WorkedTime(0), new HourlyRate(eur("40"))));
    }

    @Test
    void acceptsASingleMinute() {
        assertThat(WorkLog.create(OCT_15, new WorkedTime(1), new HourlyRate(eur("60"))).earnings()).isEqualTo(eur("1"));
    }

    @Test
    void acceptsAWholeDay() {
        assertThat(WorkLog.create(OCT_15, WorkedTime.of(24, 0), new HourlyRate(eur("10"))).earnings())
                .isEqualTo(eur("240.00"));
    }

    @Test
    void rejectsMoreThanAWholeDay() {
        assertThatIllegalArgumentException()
                .isThrownBy(() -> WorkLog.create(OCT_15, new WorkedTime(1441), new HourlyRate(eur("10"))))
                .withMessage("Work log must not exceed 24 hours: 1441 min");
    }

    @Test
    void editingChangesDayAndTimeButKeepsIdAndRate() {
        WorkLog original = WorkLog.create(OCT_15, WorkedTime.of(2, 0), new HourlyRate(eur("40")));

        WorkLog edited = original.edit(OCT_15.plusDays(1), WorkedTime.of(3, 0));

        assertThat(edited.id()).isEqualTo(original.id());
        assertThat(edited.day()).isEqualTo(OCT_15.plusDays(1));
        assertThat(edited.workedTime()).isEqualTo(WorkedTime.of(3, 0));
        assertThat(edited.earnings()).isEqualTo(eur("120.00"));
    }

    @Test
    void editingKeepsTheRules() {
        WorkLog original = WorkLog.create(OCT_15, WorkedTime.of(2, 0), new HourlyRate(eur("40")));

        assertThatIllegalArgumentException().isThrownBy(() -> original.edit(OCT_15, new WorkedTime(0)));
    }

    @Test
    void newWorkLogsGetDistinctIds() {
        HourlyRate rate = new HourlyRate(eur("40"));

        WorkLog first = WorkLog.create(OCT_15, WorkedTime.of(1, 0), rate);
        WorkLog second = WorkLog.create(OCT_15, WorkedTime.of(1, 0), rate);

        assertThat(first.id()).isNotEqualTo(second.id());
    }

    @Test
    @SuppressWarnings("DataFlowIssue")
    void rejectsNullId() {
        assertThatNullPointerException()
                .isThrownBy(() -> new WorkLog(null, OCT_15, WorkedTime.of(1, 0), new HourlyRate(eur("40"))))
                .withMessage("id must not be null");
    }

    @Test
    @SuppressWarnings("DataFlowIssue")
    void rejectsNull() {
        WorkedTime workedTime = WorkedTime.of(1, 0);
        HourlyRate rate = new HourlyRate(eur("30"));

        assertThatNullPointerException()
                .isThrownBy(() -> WorkLog.create(null, workedTime, rate))
                .withMessage("day must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> WorkLog.create(OCT_15, null, rate))
                .withMessage("workedTime must not be null");
        assertThatNullPointerException()
                .isThrownBy(() -> WorkLog.create(OCT_15, workedTime, null))
                .withMessage("hourlyRate must not be null");
    }
}
