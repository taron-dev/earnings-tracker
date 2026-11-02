package sk.taron.earningstracker.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Currency;
import java.util.List;

import org.junit.jupiter.api.Test;

class EarningWindowTest {

    static final LocalDate OCT_1 = LocalDate.of(2026, 10, 1);
    static final LocalDate OCT_31 = LocalDate.of(2026, 10, 31);
    static final EarningWindow OCTOBER = new EarningWindow(OCT_1, OCT_31);
    static final Currency EUR = Currency.getInstance("EUR");

    static Money eur(String amount) {
        return new Money(new BigDecimal(amount), EUR);
    }

    @Test
    void rejectsWindowEndingBeforeItStarts() {
        assertThatIllegalArgumentException().isThrownBy(() -> new EarningWindow(OCT_31, OCT_1));
    }

    @Test
    void allowsSingleDayWindow() {
        assertThatCode(() -> new EarningWindow(OCT_1, OCT_1)).doesNotThrowAnyException();
    }

    @Test
    void containsBothBoundaryDays() {
        assertThat(OCTOBER.contains(OCT_1)).isTrue();
        assertThat(OCTOBER.contains(LocalDate.of(2026, 10, 15))).isTrue();
        assertThat(OCTOBER.contains(OCT_31)).isTrue();
    }

    @Test
    void doesNotContainDaysOutside() {
        assertThat(OCTOBER.contains(LocalDate.of(2026, 9, 30))).isFalse();
        assertThat(OCTOBER.contains(LocalDate.of(2026, 11, 1))).isFalse();
    }

    @Test
    void overlapsWindowSharingASingleDay() {
        EarningWindow startingOnLastDay = new EarningWindow(OCT_31, LocalDate.of(2026, 11, 30));

        assertThat(OCTOBER.overlaps(startingOnLastDay)).isTrue();
        assertThat(startingOnLastDay.overlaps(OCTOBER)).isTrue();
    }

    @Test
    void overlapsWindowLyingInside() {
        EarningWindow inside = new EarningWindow(LocalDate.of(2026, 10, 10), LocalDate.of(2026, 10, 20));

        assertThat(OCTOBER.overlaps(inside)).isTrue();
        assertThat(inside.overlaps(OCTOBER)).isTrue();
    }

    @Test
    void doesNotOverlapWindowStartingTheNextDay() {
        EarningWindow november = new EarningWindow(LocalDate.of(2026, 11, 1), LocalDate.of(2026, 11, 30));

        assertThat(OCTOBER.overlaps(november)).isFalse();
        assertThat(november.overlaps(OCTOBER)).isFalse();
    }

    @Test
    void earnsNothingWithoutWorkLogs() {
        assertThat(OCTOBER.earningsFrom(List.of(), EUR)).isEqualTo(eur("0"));
    }

    @Test
    void earnsFromWorkLogsDatedInsideTheWindowEachAtItsOwnRate() {
        List<WorkLog> workLogs = List.of(
                new WorkLog(LocalDate.of(2026, 9, 30), WorkedTime.of(8, 0), new HourlyRate(eur("30"))),
                new WorkLog(OCT_1, WorkedTime.of(3, 0), new HourlyRate(eur("30"))),
                new WorkLog(OCT_31, WorkedTime.of(2, 30), new HourlyRate(eur("40"))),
                new WorkLog(LocalDate.of(2026, 11, 1), WorkedTime.of(8, 0), new HourlyRate(eur("40"))));

        assertThat(OCTOBER.earningsFrom(workLogs, EUR)).isEqualTo(eur("190.00"));
    }

    @Test
    void rejectsNull() {
        assertThatIllegalArgumentException().isThrownBy(() -> new EarningWindow(null, OCT_31));
        assertThatIllegalArgumentException().isThrownBy(() -> new EarningWindow(OCT_1, null));
        assertThatIllegalArgumentException().isThrownBy(() -> OCTOBER.contains(null));
        assertThatIllegalArgumentException().isThrownBy(() -> OCTOBER.overlaps(null));
    }
}
