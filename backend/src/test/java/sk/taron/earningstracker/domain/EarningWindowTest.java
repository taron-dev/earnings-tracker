package sk.taron.earningstracker.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import java.time.LocalDate;

import org.junit.jupiter.api.Test;

class EarningWindowTest {

    static final LocalDate OCT_1 = LocalDate.of(2026, 10, 1);
    static final LocalDate OCT_31 = LocalDate.of(2026, 10, 31);
    static final EarningWindow OCTOBER = new EarningWindow(OCT_1, OCT_31);

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
}
