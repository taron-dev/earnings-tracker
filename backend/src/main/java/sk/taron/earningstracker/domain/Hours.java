package sk.taron.earningstracker.domain;

public record Hours(long minutes) {

    public Hours {
        if (minutes < 0) {
            throw new IllegalArgumentException("Hours must not be negative: " + minutes + " min");
        }
    }

    public static Hours of(long hours, long minutes) {
        return new Hours(hours * 60 + minutes);
    }

    public Hours plus(Hours other) {
        return new Hours(minutes + other.minutes);
    }
}
