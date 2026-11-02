package sk.taron.earningstracker.domain;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Currency;

public record EarningWindow(LocalDate from, LocalDate to) {

    public EarningWindow {
        Require.nonNull(from, "from");
        Require.nonNull(to, "to");
        if (from.isAfter(to)) {
            throw new IllegalArgumentException("Earning window must not end before it starts: " + from + " – " + to);
        }
    }

    public boolean contains(LocalDate date) {
        Require.nonNull(date, "date");
        return !date.isBefore(from) && !date.isAfter(to);
    }

    public Money earningsFrom(Collection<WorkLog> workLogs, Currency currency) {
        Require.nonNull(workLogs, "workLogs");
        Require.nonNull(currency, "currency");
        return workLogs.stream()
                .filter(workLog -> contains(workLog.day()))
                .map(WorkLog::earnings)
                .reduce(new Money(BigDecimal.ZERO, currency), Money::plus);
    }

    public boolean overlaps(EarningWindow other) {
        Require.nonNull(other, "other window");
        return !from.isAfter(other.to) && !other.from.isAfter(to);
    }
}
