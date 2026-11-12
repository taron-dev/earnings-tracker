package sk.taron.earningstracker.persistence;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

@Entity
@Table(name = "work_log")
public class WorkLogEntity {

    @Id
    @Column(name = "id")
    private UUID id;

    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @Column(name = "day", nullable = false)
    private LocalDate day;

    @Column(name = "minutes", nullable = false)
    private int minutes;

    @Column(name = "rate_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal rateAmount;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "rate_currency", nullable = false, length = 3)
    private String rateCurrency;

    /** Not updatable, so saving a freshly mapped entity over an existing row keeps it. */
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected WorkLogEntity() {
    }

    WorkLogEntity(UUID id, UUID userId, LocalDate day, int minutes, BigDecimal rateAmount, String rateCurrency) {
        this.id = id;
        this.userId = userId;
        this.day = day;
        this.minutes = minutes;
        this.rateAmount = rateAmount;
        this.rateCurrency = rateCurrency;
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

    public LocalDate getDay() {
        return day;
    }

    public int getMinutes() {
        return minutes;
    }

    public BigDecimal getRateAmount() {
        return rateAmount;
    }

    public String getRateCurrency() {
        return rateCurrency;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
