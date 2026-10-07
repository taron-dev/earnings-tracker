package sk.taron.earningstracker.keepalive;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Supabase free tier pauses a project after 7 days without activity (ADR 0002).
 */
@Component
public class SupabaseKeepAlive {

    private static final Logger log = LoggerFactory.getLogger(SupabaseKeepAlive.class);

    private final JdbcTemplate jdbcTemplate;

    public SupabaseKeepAlive(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Scheduled(cron = "${app.keep-alive.cron}")
    public void ping() {
        jdbcTemplate.queryForObject("select 1", Integer.class);
        log.debug("Supabase keep-alive query executed");
    }
}
