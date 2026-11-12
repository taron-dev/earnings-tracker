package sk.taron.earningstracker.api;

/**
 * The action needs the user's current Hourly Rate, but none is set yet.
 */
public class HourlyRateNotSetException extends RuntimeException {

    public HourlyRateNotSetException() {
        super("Set your hourly rate first");
    }
}
