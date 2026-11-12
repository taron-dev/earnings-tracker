package sk.taron.earningstracker.persistence;

import java.util.UUID;

/**
 * Maps a domain object to its JPA entity and back. The owning user lives only in the entity
 * (ADR 0001), so it is passed in when building one.
 */
public interface EntityMapper<D, E> {

    D toDomain(E entity);

    E from(D domain, UUID userId);
}
