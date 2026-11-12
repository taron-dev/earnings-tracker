package sk.taron.earningstracker.persistence;

import java.math.BigDecimal;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

/**
 * A Budget Item row; it has no identity of its own and lives only inside its plan.
 */
@Embeddable
public class BudgetItemEmbeddable {

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "target_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal targetAmount;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "target_currency", nullable = false, length = 3)
    private String targetCurrency;

    protected BudgetItemEmbeddable() {
    }

    BudgetItemEmbeddable(String name, BigDecimal targetAmount, String targetCurrency) {
        this.name = name;
        this.targetAmount = targetAmount;
        this.targetCurrency = targetCurrency;
    }

    public String getName() {
        return name;
    }

    public BigDecimal getTargetAmount() {
        return targetAmount;
    }

    public String getTargetCurrency() {
        return targetCurrency;
    }
}
