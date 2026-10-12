package sk.taron.earningstracker.domain;

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
        Require.nonNull(other, "other worked time");
        return new WorkedTime(Math.addExact(minutes, other.minutes));
    }
}
