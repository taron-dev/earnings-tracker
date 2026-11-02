package sk.taron.earningstracker.domain;

import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;

import java.math.BigDecimal;
import java.util.Currency;

import org.junit.jupiter.api.Test;

class BudgetItemTest {

    static Money eur(String amount) {
        return new Money(new BigDecimal(amount), Currency.getInstance("EUR"));
    }

    @Test
    void rejectsZeroTarget() {
        assertThatIllegalArgumentException().isThrownBy(() -> new BudgetItem("Odvody", eur("0")));
    }

    @Test
    void rejectsBlankName() {
        assertThatIllegalArgumentException().isThrownBy(() -> new BudgetItem("", eur("100")));
        assertThatIllegalArgumentException().isThrownBy(() -> new BudgetItem("   ", eur("100")));
    }
}
