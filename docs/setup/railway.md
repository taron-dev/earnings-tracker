# Nasadenie backendu na Railway (krok 1.8)

Ručné kroky na GitHube a v Railway. Build a spustenie sú v repe: [`backend/Dockerfile`](../../backend/Dockerfile) a [`backend/railway.json`](../../backend/railway.json) (healthcheck `/actuator/health`). Po dokončení zaškrtni 1.8 v [PLAN.md](../PLAN.md).

## 1. GitHub repozitár

- [ ] Na github.com vytvoriť **súkromný** repozitár (napr. `earnings-tracker`), bez README a .gitignore.
- [ ] Pushnúť lokálny repozitár:
  ```sh
  git remote add origin git@github.com:<user>/earnings-tracker.git
  git push -u origin main
  ```

## 2. Railway projekt

- [ ] [railway.com](https://railway.com): prihlásiť sa cez GitHub, zvoliť plán bez uspávania (Hobby).
- [ ] **New Project → Deploy from GitHub repo** → vybrať `earnings-tracker` (povoliť Railway prístup k repu).
- [ ] V službe → **Settings**:
  - **Root Directory**: `/backend`
  - **Config file path** (Config-as-code): `/backend/railway.json` (cesta je od koreňa repa, Root Directory ju neovplyvní)
  - **Watch Paths**: `/backend/**`, aby zmeny vo frontende nespúšťali nový deploy backendu
  - **Region**: EU West (najbližšie k Supabase v Írsku)
  - **Serverless / App Sleeping**: vypnuté

## 3. Premenné prostredia

Service → **Variables**, rovnaké hodnoty ako v `backend/.env`:

- [ ] `DB_URL` (Session pooler, `jdbc:postgresql://…pooler.supabase.com:5432/postgres`)
- [ ] `DB_USERNAME` (`postgres.<project-ref>`)
- [ ] `DB_PASSWORD`
- [ ] `SUPABASE_URL`
- [ ] `CORS_ALLOWED_ORIGINS`: zatiaľ `http://localhost:3000`, v kroku 1.9 pridať produkčnú doménu frontendu (oddelené čiarkou)

`PORT` nastavuje Railway sám, backend ho číta (`server.port: ${PORT:8080}`).

## 4. Verejná adresa a overenie

- [ ] Settings → **Networking → Generate Domain** (dostaneš `https://<niečo>.up.railway.app`).
- [ ] Deploy prebehne zelene (healthcheck prešiel).
- [ ] `https://<niečo>.up.railway.app/actuator/health` vráti `{"status":"UP"}`.
- [ ] `https://<niečo>.up.railway.app/api/hello` bez tokenu vráti **401** (zabezpečenie funguje).
- [ ] Zapísať si URL backendu; vo Flutteri to bude `API_BASE_URL` (krok 1.9).
