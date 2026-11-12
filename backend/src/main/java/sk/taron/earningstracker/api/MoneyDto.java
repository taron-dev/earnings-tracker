package sk.taron.earningstracker.api;

import java.math.BigDecimal;
import java.util.Currency;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

import sk.taron.earningstracker.domain.Money;

/**
 * Money in the API: the amount travels as a string so clients never round it as a float.
 * Digits match the {@code numeric(12, 2)} columns; only EUR is accepted for now.
 */
public record MoneyDto(
        @NotNull @Digits(integer = 10, fraction = 2) @JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal amount,
        @NotNull @Pattern(regexp = "EUR", message = "only EUR is supported") String currency) {

    public static MoneyDto from(Money money) {
        return new MoneyDto(money.amount(), money.currency().getCurrencyCode());
    }

    public Money toDomain() {
        return new Money(amount, Currency.getInstance(currency));
    }
}
