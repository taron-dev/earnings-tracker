package sk.taron.earningstracker.api;

/**
 * The requested resource does not exist for the current user. A record owned by someone else
 * is reported the same way, so its existence is not revealed.
 */
public class NotFoundException extends RuntimeException {

    public NotFoundException(String message) {
        super(message);
    }
}
