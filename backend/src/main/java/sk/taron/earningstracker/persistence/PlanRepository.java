package sk.taron.earningstracker.persistence;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface PlanRepository extends JpaRepository<PlanEntity, UUID> {

    Optional<PlanEntity> findByIdAndUserId(UUID id, UUID userId);

    List<PlanWindow> findWindowsByUserId(UUID userId);

    /** Newest first, items fetched in the same query. */
    @EntityGraph(attributePaths = "items")
    List<PlanEntity> findByUserIdOrderByWindowFromDesc(UUID userId);

    /** Windows do not overlap, so at most one plan of a user covers a date. */
    @Query("select p from PlanEntity p where p.userId = :userId and :date between p.windowFrom and p.windowTo")
    Optional<PlanEntity> findContaining(UUID userId, LocalDate date);
}
