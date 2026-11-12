package sk.taron.earningstracker.hourlyrate;

import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import sk.taron.earningstracker.api.NotFoundException;
import sk.taron.earningstracker.domain.HourlyRate;
import sk.taron.earningstracker.persistence.HourlyRateEntityMapper;
import sk.taron.earningstracker.persistence.HourlyRateRepository;

@Service
public class HourlyRateService {

    private final HourlyRateRepository repository;
    private final HourlyRateEntityMapper mapper;

    HourlyRateService(HourlyRateRepository repository, HourlyRateEntityMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Transactional(readOnly = true)
    public HourlyRate current(UUID userId) {
        return repository.findById(userId)
                .map(mapper::toDomain)
                .orElseThrow(() -> new NotFoundException("Hourly rate is not set"));
    }

    /** Creates or replaces the user's rate; the row is keyed by the user, so saving is an upsert. */
    @Transactional
    public HourlyRate set(UUID userId, HourlyRate rate) {
        return mapper.toDomain(repository.save(mapper.from(rate, userId)));
    }
}
