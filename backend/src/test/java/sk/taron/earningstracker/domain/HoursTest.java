package sk.taron.earningstracker.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import org.junit.jupiter.api.Test;

class HoursTest {

    @Test
    void combinesHoursAndMinutesIntoMinutes() {
        assertThat(Hours.of(7, 20)).isEqualTo(new Hours(440));
    }

    @Test
    void rejectsNegativeMinutes() {
        assertThatIllegalArgumentException().isThrownBy(() -> new Hours(-1));
    }

    @Test
    void addsHours() {
        assertThat(Hours.of(7, 40).plus(Hours.of(1, 35))).isEqualTo(Hours.of(9, 15));
    }
}
