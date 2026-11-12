package sk.taron.earningstracker.api;

/**
 * A Plan's Earning Window overlaps the window of another Plan of the same user.
 */
public class OverlappingPlanException extends RuntimeException {

    public OverlappingPlanException(String message) {
        super(message);
    }
}
