package sk.taron.earningstracker.worklog;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatIllegalArgumentException;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Currency;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import sk.taron.earningstracker.api.HourlyRateNotSetException;
import sk.taron.earningstracker.api.NotFoundException;
import sk.taron.earningstracker.domain.HourlyRate;
import sk.taron.earningstracker.domain.Money;
import sk.taron.earningstracker.domain.WorkLog;
import sk.taron.earningstracker.domain.WorkedTime;
import sk.taron.earningstracker.hourlyrate.HourlyRateService;
import sk.taron.earningstracker.persistence.WorkLogEntity;
import sk.taron.earningstracker.persistence.WorkLogEntityMapper;
import sk.taron.earningstracker.persistence.WorkLogRepository;

class WorkLogServiceTest {

    private static final UUID USER_ID = UUID.fromString("7d3f1c2a-1b2c-4d5e-8f90-123456789abc");
    private static final LocalDate NOV_11 = LocalDate.of(2026, 11, 11);

    private final WorkLogRepository repository = mock(WorkLogRepository.class);
    private final HourlyRateService hourlyRateService = mock(HourlyRateService.class);
    private final WorkLogEntityMapper mapper = new WorkLogEntityMapper();
    private final WorkLogService service = new WorkLogService(repository, hourlyRateService, mapper);

    @Test
    void recordingUsesCurrentRateAndStoresLogForUser() {
        given(hourlyRateService.find(USER_ID)).willReturn(Optional.of(eurPerHour("40")));
        given(repository.save(any(WorkLogEntity.class))).willAnswer(invocation -> invocation.getArgument(0));

        WorkLog recorded = service.record(USER_ID, NOV_11, WorkedTime.of(2, 30));

        assertThat(recorded.day()).isEqualTo(NOV_11);
        assertThat(recorded.workedTime()).isEqualTo(WorkedTime.of(2, 30));
        assertThat(recorded.hourlyRate()).isEqualTo(eurPerHour("40"));
        ArgumentCaptor<WorkLogEntity> stored = ArgumentCaptor.forClass(WorkLogEntity.class);
        then(repository).should().save(stored.capture());
        assertThat(stored.getValue().getUserId()).isEqualTo(USER_ID);
        assertThat(stored.getValue().getId()).isEqualTo(recorded.id());
    }

    @Test
    void recordingWithoutHourlyRateIsRefused() {
        given(hourlyRateService.find(USER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> service.record(USER_ID, NOV_11, WorkedTime.of(1, 0)))
                .isInstanceOf(HourlyRateNotSetException.class);
        then(repository).shouldHaveNoInteractions();
    }

    @Test
    void editingKeepsTheRateTheLogWasRecordedWith() {
        WorkLog original = WorkLog.create(NOV_11, WorkedTime.of(2, 0), eurPerHour("40"));
        given(repository.findByIdAndUserId(original.id(), USER_ID)).willReturn(Optional.of(mapper.from(original, USER_ID)));
        given(hourlyRateService.find(USER_ID)).willReturn(Optional.of(eurPerHour("50")));
        given(repository.save(any(WorkLogEntity.class))).willAnswer(invocation -> invocation.getArgument(0));

        WorkLog edited = service.edit(USER_ID, original.id(), NOV_11.plusDays(1), WorkedTime.of(3, 0));

        assertThat(edited).isEqualTo(new WorkLog(original.id(), NOV_11.plusDays(1), WorkedTime.of(3, 0), eurPerHour("40")));
        then(repository).should().save(any(WorkLogEntity.class));
    }

    @Test
    void editingUnknownOrForeignLogIsNotFound() {
        UUID id = UUID.randomUUID();
        given(repository.findByIdAndUserId(id, USER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> service.edit(USER_ID, id, NOV_11, WorkedTime.of(1, 0)))
                .isInstanceOf(NotFoundException.class)
                .hasMessage("Work log not found");
    }

    @Test
    void gettingReturnsOwnLog() {
        WorkLog log = WorkLog.create(NOV_11, WorkedTime.of(2, 0), eurPerHour("40"));
        given(repository.findByIdAndUserId(log.id(), USER_ID)).willReturn(Optional.of(mapper.from(log, USER_ID)));

        assertThat(service.get(USER_ID, log.id())).isEqualTo(log);
    }

    @Test
    void deletingRemovesOwnLog() {
        WorkLog log = WorkLog.create(NOV_11, WorkedTime.of(2, 0), eurPerHour("40"));
        WorkLogEntity entity = mapper.from(log, USER_ID);
        given(repository.findByIdAndUserId(log.id(), USER_ID)).willReturn(Optional.of(entity));

        service.delete(USER_ID, log.id());

        then(repository).should().delete(entity);
    }

    @Test
    void deletingUnknownOrForeignLogIsNotFound() {
        UUID id = UUID.randomUUID();
        given(repository.findByIdAndUserId(id, USER_ID)).willReturn(Optional.empty());

        assertThatThrownBy(() -> service.delete(USER_ID, id)).isInstanceOf(NotFoundException.class);
        then(repository).should(never()).delete(any(WorkLogEntity.class));
    }

    @Test
    void listingReturnsUsersLogsInRangeNewestFirst() {
        WorkLog newer = WorkLog.create(NOV_11, WorkedTime.of(1, 0), eurPerHour("40"));
        WorkLog older = WorkLog.create(NOV_11.minusDays(3), WorkedTime.of(2, 0), eurPerHour("40"));
        LocalDate from = LocalDate.of(2026, 11, 1);
        LocalDate to = LocalDate.of(2026, 11, 30);
        given(repository.findByUserIdAndDayBetweenOrderByDayDescCreatedAtDesc(USER_ID, from, to))
                .willReturn(List.of(mapper.from(newer, USER_ID), mapper.from(older, USER_ID)));

        assertThat(service.list(USER_ID, from, to)).containsExactly(newer, older);
    }

    @Test
    void listingRejectsRangeEndingBeforeItStarts() {
        assertThatIllegalArgumentException()
                .isThrownBy(() -> service.list(USER_ID, NOV_11, NOV_11.minusDays(1)))
                .withMessage("Range must not end before it starts: 2026-11-11 – 2026-11-10");
    }

    private static HourlyRate eurPerHour(String amount) {
        return new HourlyRate(new Money(new BigDecimal(amount), Currency.getInstance("EUR")));
    }
}
