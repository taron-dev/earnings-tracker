package sk.taron.earningstracker.persistence;

import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OrderColumn;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

@Entity
@Table(name = "plan")
public class PlanEntity {

    @Id
    @Column(name = "id")
    private UUID id;

    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @Column(name = "window_from", nullable = false)
    private LocalDate windowFrom;

    @Column(name = "window_to", nullable = false)
    private LocalDate windowTo;

    @Column(name = "essentials_count", nullable = false)
    private int essentialsCount;

    /** Funding order is the list order, stored in {@code position}. */
    @ElementCollection
    @CollectionTable(name = "budget_item", joinColumns = @JoinColumn(name = "plan_id"))
    @OrderColumn(name = "position")
    private List<BudgetItemEmbeddable> items = new ArrayList<>();

    /** Not updatable, so saving a freshly mapped entity over an existing row keeps it. */
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected PlanEntity() {
    }

    PlanEntity(UUID id, UUID userId, LocalDate windowFrom, LocalDate windowTo, int essentialsCount,
               List<BudgetItemEmbeddable> items) {
        this.id = id;
        this.userId = userId;
        this.windowFrom = windowFrom;
        this.windowTo = windowTo;
        this.essentialsCount = essentialsCount;
        this.items = new ArrayList<>(items);
    }

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public UUID getUserId() {
        return userId;
    }

    public LocalDate getWindowFrom() {
        return windowFrom;
    }

    public LocalDate getWindowTo() {
        return windowTo;
    }

    public int getEssentialsCount() {
        return essentialsCount;
    }

    public List<BudgetItemEmbeddable> getItems() {
        return List.copyOf(items);
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
