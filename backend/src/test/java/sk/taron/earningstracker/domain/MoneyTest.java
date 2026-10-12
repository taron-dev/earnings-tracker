package sk.taron.earningstracker.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import java.math.BigDecimal;
import java.util.Currency;

import org.junit.jupiter.api.Test;

class MoneyTest {

    static final Currency EUR = Currency.getInstance("EUR");

    static Money eur(String amount) {
        return new Money(new BigDecimal(amount), EUR);
    }

    @Test
    void amountIsNormalizedToCurrencyFractionDigits() {
        assertThat(new Money(new BigDecimal("10"), EUR)).isEqualTo(new Money(new BigDecimal("10.00"), EUR));
    }

    @Test
    void rejectsNegativeAmount() {
        assertThatIllegalArgumentException().isThrownBy(() -> new Money(new BigDecimal("-0.01"), EUR));
    }

    @Test
    void rejectsMoreFractionDigitsThanCurrencyHas() {
        assertThatIllegalArgumentException().isThrownBy(() -> new Money(new BigDecimal("10.001"), EUR));
    }

    @Test
    void addsAmounts() {
        assertThat(eur("10.50").plus(eur("2.75"))).isEqualTo(eur("13.25"));
    }

    @Test
    void subtractsAmounts() {
        assertThat(eur("10.50").minus(eur("2.75"))).isEqualTo(eur("7.75"));
    }

    @Test
    void rejectsSubtractionBelowZero() {
        assertThatIllegalArgumentException().isThrownBy(() -> eur("2.75").minus(eur("10.50")));
    }

    @Test
    void subtractsDownToZeroAtMost() {
        assertThat(eur("2.75").minusOrZero(eur("10.50"))).isEqualTo(eur("0"));
        assertThat(eur("10.50").minusOrZero(eur("2.75"))).isEqualTo(eur("7.75"));
    }

    @Test
    void rejectsOperationsAcrossCurrencies() {
        Money usd = new Money(new BigDecimal("1.00"), Currency.getInstance("USD"));

        assertThatIllegalArgumentException().isThrownBy(() -> eur("1.00").plus(usd));
        assertThatIllegalArgumentException().isThrownBy(() -> eur("1.00").minus(usd));
        assertThatIllegalArgumentException().isThrownBy(() -> eur("1.00").minusOrZero(usd));
        assertThatIllegalArgumentException().isThrownBy(() -> eur("1.00").isAtLeast(usd));
    }

    @Test
    void comparesWhetherAmountIsAtLeastAnother() {
        assertThat(eur("10.00").isAtLeast(eur("9.99"))).isTrue();
        assertThat(eur("10.00").isAtLeast(eur("10"))).isTrue();
        assertThat(eur("9.99").isAtLeast(eur("10.00"))).isFalse();
    }

    @Test
    void rejectsNull() {
        assertThatIllegalArgumentException().isThrownBy(() -> new Money(null, EUR));
        assertThatIllegalArgumentException().isThrownBy(() -> new Money(BigDecimal.ONE, null));
        assertThatIllegalArgumentException().isThrownBy(() -> eur("1.00").plus(null));
        assertThatIllegalArgumentException().isThrownBy(() -> eur("1.00").minus(null));
        assertThatIllegalArgumentException().isThrownBy(() -> eur("1.00").minusOrZero(null));
        assertThatIllegalArgumentException().isThrownBy(() -> eur("1.00").isAtLeast(null));
    }

    @Test
    void rejectsCurrencyWithoutFractionDigits() {
        assertThatIllegalArgumentException().isThrownBy(() -> new Money(BigDecimal.TEN, Currency.getInstance("XXX")));
    }
}
