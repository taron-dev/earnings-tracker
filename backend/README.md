# Earnings Tracker – backend

Spring Boot backend: vlastní doménovú logiku a všetok prístup k dátam. Supabase slúži len ako hostovaný Postgres a vydavateľ JWT tokenov ([ADR 0001](../docs/adr/0001-flutter-spring-supabase-as-db-and-auth-only.md)). Pojmy sú v [CONTEXT.md](../CONTEXT.md).

## Stack

- Java 21, Spring Boot 4.1.1, Gradle (Groovy DSL)
- Spring Web MVC, Spring Security ako OAuth2 resource server (overenie Supabase JWT)
- Spring Data JPA, PostgreSQL driver, Liquibase
- Bean Validation, Actuator (len `/actuator/health`)

## Čo je hotové

| Súbor | Účel |
|---|---|
| `security/SecurityConfig.java` | Všetko okrem `/actuator/health` vyžaduje platný token. Stateless, bez CSRF, CORS pre `/api/**` podľa `CORS_ALLOWED_ORIGINS`. |
| `hello/HelloController.java` | `GET /api/hello` → `{ "userId": "<sub>", "message": "Hello, <email>" }`. Overuje celú cestu Flutter → Supabase token → Spring. |
| `keepalive/SupabaseKeepAlive.java` | Každých 12 h `select 1`, aby sa Supabase free tier nepozastavil ([ADR 0002](../docs/adr/0002-always-on-backend-hosting.md)). Cron v `app.keep-alive.cron`. |
| `resources/application.yml` | Konfigurácia, tajné hodnoty len cez env premenné. |
| `resources/db/changelog/db.changelog-master.yaml` | Liquibase changelog, zatiaľ prázdny. Hibernate schému iba validuje (`ddl-auto: validate`). |
| `test/.../HelloControllerTest.java` | `@WebMvcTest`: s tokenom 200 a správne údaje, bez tokenu 401. |

### Overenie tokenu

Konfigurácia v `spring.security.oauth2.resourceserver.jwt`:

- verejné kľúče z `${SUPABASE_URL}/auth/v1/.well-known/jwks.json`
- issuer `${SUPABASE_URL}/auth/v1`
- audience `authenticated`
- algoritmy ES256 a RS256 (legacy HS256 tokeny Supabase sa neoveria)

Doména pozná používateľa len ako `sub` z tokenu (`user_id`).

## Konfigurácia

Hodnoty sa čítajú z env premenných; lokálne z `backend/.env` (git-ignored, načíta sa cez `spring.config.import`). Šablóna je v [`.env.example`](.env.example).

| Premenná | Popis |
|---|---|
| `DB_URL` | JDBC URL na Supabase **Session pooler** (priame pripojenie je len IPv6) |
| `DB_USERNAME` | `postgres.<project-ref>` |
| `DB_PASSWORD` | heslo databázy |
| `SUPABASE_URL` | `https://<project-ref>.supabase.co` |
| `CORS_ALLOWED_ORIGINS` | povolené originy Flutter webu, oddelené čiarkou (default `http://localhost:3000`) |

Nastavenie Supabase Auth: [docs/setup/supabase-auth.md](../docs/setup/supabase-auth.md).

## Prostredia

| Prostredie | URL |
|---|---|
| Lokálne | http://localhost:8080 |
| Produkcia (Railway, Dockerfile builder) | https://earnings-tracker-production-984f.up.railway.app |

Nasadenie: [docs/setup/railway.md](../docs/setup/railway.md).

## Spustenie

```sh
cp .env.example .env   # a vyplniť
./gradlew bootRun      # http://localhost:8080/actuator/health
./gradlew test
```

Testy nepotrebujú databázu ani Supabase.
