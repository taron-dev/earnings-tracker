package sk.taron.earningstracker.persistence;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

public interface WorkLogRepository extends JpaRepository<WorkLogEntity, UUID> {

    Optional<WorkLogEntity> findByIdAndUserId(UUID id, UUID userId);

    /** Both days included. */
    List<WorkLogEntity> findByUserIdAndDayBetweenOrderByDayDescCreatedAtDesc(UUID userId, LocalDate from, LocalDate to);
}
