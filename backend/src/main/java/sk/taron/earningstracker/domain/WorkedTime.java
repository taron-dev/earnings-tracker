package sk.taron.earningstracker.domain;

import java.util.Objects;

public record WorkedTime(long minutes) {

    public WorkedTime {
        if (minutes < 0) {
            throw new IllegalArgumentException("Worked time must not be negative: " + minutes + " min");
        }
    }

    public static WorkedTime of(long hours, long minutes) {
        if (hours < 0 || minutes < 0) {
            throw new IllegalArgumentException("Hours and minutes must not be negative: " + hours + " h " + minutes + " min");
        }
        return new WorkedTime(Math.addExact(Math.multiplyExact(hours, 60), minutes));
    }

    public WorkedTime plus(WorkedTime other) {
        Objects.requireNonNull(other, "other worked time must not be null");
        return new WorkedTime(Math.addExact(minutes, other.minutes));
    }
}
