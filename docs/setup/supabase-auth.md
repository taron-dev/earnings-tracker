# Nastavenie Supabase Auth (krok 1.2)

Kroky, ktoré sa robia ručne v dashboarde Supabase a Google Cloud Console. Po dokončení zaškrtni 1.2 v [PLAN.md](../PLAN.md).

## 1. Magic link (Email)

- [X] Authentication → Sign In / Providers → **Email**: zapnuté.
- [X] Ak chceš len magic link bez hesla, nevypĺňaj heslo vo Flutteri; provider Email pokrýva oboje.
- [ ] (Voliteľné) Authentication → Emails → šablóna **Magic Link**: upraviť text po slovensky.
- [ ] Pozor: vstavaný SMTP Supabase posiela len pár emailov za hodinu a iba na adresy členov tímu projektu. Na vývoj stačí, pre betu nastaviť vlastný SMTP (Authentication → Emails → SMTP Settings): SMTP schránky na vlastnej doméne (s SPF, DKIM, DMARC v DNS) alebo transakčná služba (Resend, Brevo, Postmark, Amazon SES).

## 2. Google prihlásenie

V [Google Cloud Console](https://console.cloud.google.com/):

- [X] Vytvoriť (alebo vybrať) projekt.
- [X] APIs & Services → **OAuth consent screen**: typ External, názov aplikácie, support email; v testovacom režime pridať svoj Google účet medzi Test users.
- [X] APIs & Services → Credentials → **Create credentials → OAuth client ID**, typ **Web application**.
  - Authorized JavaScript origins: `http://localhost:3000`
  - Authorized redirect URIs: `https://<project-ref>.supabase.co/auth/v1/callback` (presnú URL ukáže Supabase pri Google provideri)
- [X] Skopírovať **Client ID** a **Client secret**.

V Supabase:

- [X] Authentication → Sign In / Providers → **Google**: zapnúť, vložiť Client ID a Client secret, uložiť.

## 3. URL Configuration

- [X] Authentication → URL Configuration → **Site URL**: `http://localhost:3000` (po nasadení v kroku 1.9 zmeniť na produkčnú doménu).
- [X] **Redirect URLs**: pridať `http://localhost:3000/**`.

## 4. JWT Signing Keys

Backend overuje tokeny cez verejné kľúče (JWKS), preto musia byť asymetrické.

- [X] Project Settings → **JWT Keys** (JWT Signing Keys): aktuálny kľúč je typu **ECC (P-256) / ES256** alebo **RSA / RS256**.
- [X] Ak je aktívny len **Legacy JWT secret (HS256)**: vytvoriť nový asymetrický kľúč a prepnúť ho na aktuálny (rotate).
- [X] Overiť v prehliadači, že `https://<project-ref>.supabase.co/auth/v1/.well-known/jwks.json` vracia aspoň jeden kľúč.

## 5. Hodnoty, ktoré si zapísať

Budú treba v `backend/.env` (krok 1.4) a vo Flutteri (krok 1.6):

- [X] **Project URL** (`https://<project-ref>.supabase.co`) → `SUPABASE_URL`
- [X] **Publishable key** (alebo legacy anon key) → Flutter; je verejný, nepatrí do backendu
- [X] **Session pooler** connection string (tlačidlo Connect) → `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`

## 6. Data API

Supabase Data API (REST nad schémou `public`) nepoužívame, všetok prístup k dátam ide cez Spring ([ADR 0001](../adr/0001-flutter-spring-supabase-as-db-and-auth-only.md)). Inak by tabuľky vytvorené Liquibase boli dostupné komukoľvek s publishable key.

- [x] Project Settings → **Data API**: vypnuté.
