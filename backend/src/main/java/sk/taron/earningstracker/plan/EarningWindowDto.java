package sk.taron.earningstracker.plan;

import java.time.LocalDate;

import jakarta.validation.constraints.NotNull;

import sk.taron.earningstracker.domain.EarningWindow;

/** Both days included. */
public record EarningWindowDto(@NotNull LocalDate from, @NotNull LocalDate to) {

    static EarningWindowDto from(EarningWindow window) {
        return new EarningWindowDto(window.from(), window.to());
    }

    EarningWindow toDomain() {
        return new EarningWindow(from, to);
    }
}
