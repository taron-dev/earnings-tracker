package sk.taron.earningstracker.persistence;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

public interface HourlyRateRepository extends JpaRepository<HourlyRateEntity, UUID> {
}
