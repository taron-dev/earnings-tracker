package sk.taron.earningstracker.persistence;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

public interface PlanRepository extends JpaRepository<PlanEntity, UUID> {

    Optional<PlanEntity> findByIdAndUserId(UUID id, UUID userId);

    List<PlanWindow> findWindowsByUserId(UUID userId);
}
