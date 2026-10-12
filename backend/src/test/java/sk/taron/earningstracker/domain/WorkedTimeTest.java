package sk.taron.earningstracker.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatExceptionOfType;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import org.junit.jupiter.api.Test;

class WorkedTimeTest {

    @Test
    void combinesHoursAndMinutesIntoMinutes() {
        assertThat(WorkedTime.of(7, 20)).isEqualTo(new WorkedTime(440));
    }

    @Test
    void rejectsNegativeMinutes() {
        assertThatIllegalArgumentException().isThrownBy(() -> new WorkedTime(-1));
    }

    @Test
    void rejectsNegativeHoursOrMinutesPart() {
        assertThatIllegalArgumentException().isThrownBy(() -> WorkedTime.of(7, -20));
        assertThatIllegalArgumentException().isThrownBy(() -> WorkedTime.of(-1, 70));
    }

    @Test
    void rejectsOverflowInsteadOfWrappingAround() {
        assertThatExceptionOfType(ArithmeticException.class).isThrownBy(() -> WorkedTime.of(Long.MAX_VALUE, 0));
        assertThatExceptionOfType(ArithmeticException.class)
                .isThrownBy(() -> new WorkedTime(Long.MAX_VALUE).plus(new WorkedTime(1)));
    }

    @Test
    void addsWorkedTime() {
        assertThat(WorkedTime.of(7, 40).plus(WorkedTime.of(1, 35))).isEqualTo(WorkedTime.of(9, 15));
    }

    @Test
    void rejectsNull() {
        assertThatIllegalArgumentException().isThrownBy(() -> WorkedTime.of(1, 0).plus(null));
    }
}
