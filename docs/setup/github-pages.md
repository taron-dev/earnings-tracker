# Nasadenie frontendu na GitHub Pages (krok 1.9)

Produkčná URL frontendu: https://taron-dev.github.io/earnings-tracker/

Build a deploy robí workflow [`.github/workflows/frontend-pages.yml`](../../.github/workflows/frontend-pages.yml) pri každom pushi do `main`, ktorý mení `frontend/`. Aplikácia beží v podadresári `/earnings-tracker/` (`--base-href`). Po dokončení zaškrtni 1.9 v [PLAN.md](../PLAN.md).

## 1. GitHub

- [ ] Settings → General → Danger Zone → **Change visibility → Public** (Pages zadarmo len pre verejné repo).
- [ ] Settings → **Pages** → Build and deployment → Source: **GitHub Actions**.
- [ ] Settings → Secrets and variables → Actions → záložka **Variables** → New repository variable (sú verejné, skončia v prehliadači, preto nie Secrets):
  - `SUPABASE_URL`: `https://<project-ref>.supabase.co`
  - `SUPABASE_PUBLISHABLE_KEY`: publishable key
  - `API_BASE_URL`: `https://earnings-tracker-production-984f.up.railway.app`

## 2. Supabase

Authentication → URL Configuration:

- [ ] **Site URL**: `https://taron-dev.github.io/earnings-tracker/`
- [ ] **Redirect URLs**: pridať `https://taron-dev.github.io/earnings-tracker/**` (`http://localhost:3000/**` nechať kvôli vývoju).

## 3. Google Cloud Console

- [ ] APIs & Services → Credentials → OAuth client → **Authorized JavaScript origins**: pridať `https://taron-dev.github.io`.

## 4. Railway (CORS backendu)

- [ ] Variables → `CORS_ALLOWED_ORIGINS`: `http://localhost:3000,https://taron-dev.github.io` (origin je bez cesty `/earnings-tracker/`). Railway potom backend reštartuje.

## 5. Deploy a overenie

- [ ] Pushnúť `main` (alebo Actions → *Frontend to GitHub Pages* → Run workflow).
- [ ] Workflow prebehne zelene.
- [ ] Na https://taron-dev.github.io/earnings-tracker/ sa prihlásiť cez Google aj cez magic link a vidieť „Hello, &lt;email&gt;".
