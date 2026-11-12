package sk.taron.earningstracker.plan;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import sk.taron.earningstracker.api.MoneyDto;
import sk.taron.earningstracker.domain.BudgetItem;

public record BudgetItemDto(@NotBlank String name, @NotNull @Valid MoneyDto target) {

    static BudgetItemDto from(BudgetItem item) {
        return new BudgetItemDto(item.name(), MoneyDto.from(item.target()));
    }

    BudgetItem toDomain() {
        return new BudgetItem(name, target.toDomain());
    }
}
