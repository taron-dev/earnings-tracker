package sk.taron.earningstracker.domain;

final class Require {

    private Require() {
    }

    static <T> T nonNull(T value, String name) {
        if (value == null) {
            throw new IllegalArgumentException(name + " must not be null");
        }
        return value;
    }
}
