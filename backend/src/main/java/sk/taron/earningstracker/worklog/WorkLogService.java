package sk.taron.earningstracker.worklog;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import sk.taron.earningstracker.api.HourlyRateNotSetException;
import sk.taron.earningstracker.api.NotFoundException;
import sk.taron.earningstracker.domain.HourlyRate;
import sk.taron.earningstracker.domain.WorkLog;
import sk.taron.earningstracker.domain.WorkedTime;
import sk.taron.earningstracker.hourlyrate.HourlyRateService;
import sk.taron.earningstracker.persistence.WorkLogEntity;
import sk.taron.earningstracker.persistence.WorkLogEntityMapper;
import sk.taron.earningstracker.persistence.WorkLogRepository;

@Service
public class WorkLogService {

    private final WorkLogRepository repository;
    private final HourlyRateService hourlyRateService;
    private final WorkLogEntityMapper mapper;

    WorkLogService(WorkLogRepository repository, HourlyRateService hourlyRateService, WorkLogEntityMapper mapper) {
        this.repository = repository;
        this.hourlyRateService = hourlyRateService;
        this.mapper = mapper;
    }

    /** A new Work Log carries the Hourly Rate that is current when it is recorded. */
    @Transactional
    public WorkLog record(UUID userId, LocalDate day, WorkedTime workedTime) {
        HourlyRate currentRate = hourlyRateService.find(userId).orElseThrow(HourlyRateNotSetException::new);
        return save(WorkLog.create(day, workedTime, currentRate), userId);
    }

    @Transactional
    public WorkLog edit(UUID userId, UUID id, LocalDate day, WorkedTime workedTime) {
        return save(get(userId, id).edit(day, workedTime), userId);
    }

    @Transactional(readOnly = true)
    public WorkLog get(UUID userId, UUID id) {
        return mapper.toDomain(findEntity(userId, id));
    }

    /** Work Logs dated from–to, both days included, newest first. */
    @Transactional(readOnly = true)
    public List<WorkLog> list(UUID userId, LocalDate from, LocalDate to) {
        if (from.isAfter(to)) {
            throw new IllegalArgumentException("Range must not end before it starts: " + from + " – " + to);
        }
        return repository.findByUserIdAndDayBetweenOrderByDayDescCreatedAtDesc(userId, from, to).stream()
                .map(mapper::toDomain)
                .toList();
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        repository.delete(findEntity(userId, id));
    }

    /** Someone else's log is reported as not found, so its existence is not revealed. */
    private WorkLogEntity findEntity(UUID userId, UUID id) {
        return repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new NotFoundException("Work log not found"));
    }

    private WorkLog save(WorkLog workLog, UUID userId) {
        return mapper.toDomain(repository.save(mapper.from(workLog, userId)));
    }
}
