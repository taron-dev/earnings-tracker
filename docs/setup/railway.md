# Nasadenie backendu na Railway (krok 1.8)

Produkčná URL backendu: https://earnings-tracker-production-984f.up.railway.app

Ručné kroky na GitHube a v Railway. Build a spustenie sú v repe: [`backend/Dockerfile`](../../backend/Dockerfile) a [`backend/railway.json`](../../backend/railway.json) (healthcheck `/actuator/health`). Po dokončení zaškrtni 1.8 v [PLAN.md](../PLAN.md).

## 1. GitHub repozitár

- [x] Na github.com vytvoriť **súkromný** repozitár (napr. `earnings-tracker`), bez README a .gitignore.
- [x] Pushnúť lokálny repozitár:
  ```sh
  git remote add origin git@github.com:<user>/earnings-tracker.git
  git push -u origin main
  ```

## 2. Railway projekt

- [x] [railway.com](https://railway.com): prihlásiť sa cez GitHub, zvoliť plán bez uspávania (Hobby).
- [x] **New Project → Deploy from GitHub repo** → vybrať `earnings-tracker` (povoliť Railway prístup k repu).
- [x] V službe → **Settings**:
  - **Root Directory**: `/backend`
  - **Builder**: `Dockerfile` (nie predvolený Railpack). V UI treba prepnúť ručne, `railway.json` to samo nenastavilo.
  - **Config file path** (Config-as-code): `/backend/railway.json` (cesta je od koreňa repa, Root Directory ju neovplyvní)
  - **Watch Paths**: `/backend/**`, aby zmeny vo frontende nespúšťali nový deploy backendu
  - **Region**: EU West (najbližšie k Supabase v Írsku)
  - **Serverless / App Sleeping**: vypnuté

## 3. Premenné prostredia

Service → **Variables**, rovnaké hodnoty ako v `backend/.env`:

- [x] `DB_URL` (Session pooler, `jdbc:postgresql://…pooler.supabase.com:5432/postgres`)
- [x] `DB_USERNAME` (`postgres.<project-ref>`)
- [x] `DB_PASSWORD`
- [x] `SUPABASE_URL`
- [x] `CORS_ALLOWED_ORIGINS`: zatiaľ `http://localhost:3000`, v kroku 1.9 pridať produkčnú doménu frontendu (oddelené čiarkou)

`PORT` nastavuje Railway sám, backend ho číta (`server.port: ${PORT:8080}`).

## 4. Verejná adresa a overenie

- [x] Settings → **Networking → Generate Domain** (dostaneš `https://<niečo>.up.railway.app`).
- [x] Deploy prebehne zelene (healthcheck prešiel).
- [x] `https://<niečo>.up.railway.app/actuator/health` vráti `{"status":"UP"}`.
- [x] `https://<niečo>.up.railway.app/api/hello` bez tokenu vráti **401** (zabezpečenie funguje).
- [x] Zapísať si URL backendu; vo Flutteri to bude `API_BASE_URL` (krok 1.9).
