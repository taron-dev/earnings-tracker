package sk.taron.earningstracker.domain;

import java.time.LocalDate;

public record EarningWindow(LocalDate from, LocalDate to) {

    public EarningWindow {
        if (from.isAfter(to)) {
            throw new IllegalArgumentException("Earning window must not end before it starts: " + from + " – " + to);
        }
    }

    public boolean contains(LocalDate date) {
        return !date.isBefore(from) && !date.isAfter(to);
    }

    public boolean overlaps(EarningWindow other) {
        return !from.isAfter(other.to) && !other.from.isAfter(to);
    }
}
