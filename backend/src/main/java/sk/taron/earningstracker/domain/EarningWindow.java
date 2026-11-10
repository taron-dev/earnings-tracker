package sk.taron.earningstracker.domain;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Currency;
import java.util.Objects;

public record EarningWindow(LocalDate from, LocalDate to) {

    public EarningWindow {
        Objects.requireNonNull(from, "from must not be null");
        Objects.requireNonNull(to, "to must not be null");
        if (from.isAfter(to)) {
            throw new IllegalArgumentException("Earning window must not end before it starts: " + from + " – " + to);
        }
    }

    public boolean contains(LocalDate date) {
        Objects.requireNonNull(date, "date must not be null");
        return !date.isBefore(from) && !date.isAfter(to);
    }

    public Money earningsFrom(Collection<WorkLog> workLogs, Currency currency) {
        Objects.requireNonNull(workLogs, "workLogs must not be null");
        Objects.requireNonNull(currency, "currency must not be null");
        return workLogs.stream()
                .filter(workLog -> contains(workLog.day()))
                .map(WorkLog::earnings)
                .reduce(new Money(BigDecimal.ZERO, currency), Money::plus);
    }

    public boolean overlaps(EarningWindow other) {
        Objects.requireNonNull(other, "other window must not be null");
        return !from.isAfter(other.to) && !other.from.isAfter(to);
    }
}
