# Earnings Tracker – frontend

Flutter web klient. Prihlasuje cez Supabase Auth a všetky dáta berie z vlastného Spring backendu ([ADR 0001](../docs/adr/0001-flutter-spring-supabase-as-db-and-auth-only.md)).

## Stack

- Flutter 3.47.6 cez FVM (`.fvmrc`), platforma web
- `supabase_flutter`: prihlásenie (Google, magic link) a access token
- `dio`: HTTP klient na backend, interceptor pridá `Authorization: Bearer <token>`
- `go_router`: routing; neprihlásený používateľ ide vždy na `/login`

## Štruktúra

| Súbor | Účel |
|---|---|
| `lib/main.dart` | Inicializácia Supabase, `MaterialApp.router` |
| `lib/config.dart` | Konfigurácia z `--dart-define-from-file` |
| `lib/router.dart` | Routy `/` a `/login`, presmerovanie podľa stavu prihlásenia |
| `lib/auth/login_page.dart` | Google prihlásenie a magic link |
| `lib/api/api_client.dart` | `Dio` s tokenom zo Supabase |
| `lib/home/home_page.dart` | Volá `GET /api/hello` a zobrazí pozdrav, odhlásenie |

## Konfigurácia

Skopíruj `env.example.json` do `env.json` (git-ignored) a vyplň:

| Kľúč | Popis |
|---|---|
| `SUPABASE_URL` | `https://<project-ref>.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | Publishable key (alebo legacy anon key), je verejný |
| `API_BASE_URL` | URL backendu, lokálne `http://localhost:8080` |

## Prostredia

| Prostredie | URL |
|---|---|
| Lokálne | http://localhost:3000 |
| Produkcia (GitHub Pages) | https://taron-dev.github.io/earnings-tracker/ |

Produkčný build a deploy robí [GitHub Actions workflow](../.github/workflows/frontend-pages.yml), hodnoty `env.json` berie z repo Variables. Postup: [docs/setup/github-pages.md](../docs/setup/github-pages.md).

## Spustenie

```sh
fvm flutter run -d chrome --web-port 3000 --dart-define-from-file=env.json
fvm flutter test
```

Port 3000 musí sedieť so Supabase Redirect URLs, Google OAuth origins a `CORS_ALLOWED_ORIGINS` v backende.
