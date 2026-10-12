package sk.taron.earningstracker.domain;

import java.math.BigDecimal;
import java.util.Currency;

public record Money(BigDecimal amount, Currency currency) {

    public Money {
        if (amount.signum() < 0) {
            throw new IllegalArgumentException("Money must not be negative: " + amount);
        }
        int fractionDigits = currency.getDefaultFractionDigits();
        if (amount.stripTrailingZeros().scale() > fractionDigits) {
            throw new IllegalArgumentException(
                    "Money " + amount + " has more fraction digits than " + currency + " allows (" + fractionDigits + ")");
        }
        amount = amount.setScale(fractionDigits);
    }

    public Money plus(Money other) {
        requireSameCurrency(other);
        return new Money(amount.add(other.amount), currency);
    }

    public Money minus(Money other) {
        requireSameCurrency(other);
        return new Money(amount.subtract(other.amount), currency);
    }

    public Money minusOrZero(Money other) {
        requireSameCurrency(other);
        return new Money(amount.subtract(other.amount).max(BigDecimal.ZERO), currency);
    }

    public boolean isAtLeast(Money other) {
        requireSameCurrency(other);
        return amount.compareTo(other.amount) >= 0;
    }

    private void requireSameCurrency(Money other) {
        if (!currency.equals(other.currency)) {
            throw new IllegalArgumentException("Cannot combine " + currency + " with " + other.currency);
        }
    }
}
