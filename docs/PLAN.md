# Plán projektu

Pojmy sú definované v [CONTEXT.md](../CONTEXT.md), technologické rozhodnutia v [docs/adr](./adr).

## Postup do hotovej aplikácie

1. **Kostra**: Spring Boot s overením Supabase JWT, Supabase (auth a Postgres, región EÚ), Flutter web s prihlásením, nasadenie na PaaS bez uspávania. Hotové, keď po prihlásení naživo vidím „Hello, user".
   - [x] 1.1 Supabase projekt, Postgres v EÚ (Írsko, eu-west-1)
   - [X] 1.2 Supabase Auth ([postup](./setup/supabase-auth.md)): zapnúť Google a magic link (email), nastaviť Site URL a Redirect URLs, overiť, že JWT Signing Keys sú asymetrické (ES256 alebo RS256, nie legacy HS256)
   - [x] 1.3 Spring kostra v `backend/`: overenie JWT (issuer, audience `authenticated`, JWKS), `GET /api/hello`, CORS, keep-alive dotaz, test kontroléra
   - [X] 1.4 Backend lokálne proti Supabase: skopírovať `backend/.env.example` do `.env` a vyplniť (Session pooler), spustiť, `/actuator/health` je UP a Liquibase prebehne
   - [x] 1.5 Flutter kostra v `frontend/`: Flutter SDK cez FVM (3.47.6, `.fvmrc`), `flutter create` s platformou web
   - [x] 1.6 Prihlásenie vo Flutteri cez `supabase_flutter` (Google a magic link), `go_router` presmerovanie na `/login`
   - [x] 1.7 Flutter volá `/api/hello` cez `dio` s access tokenom, lokálne end-to-end vidím „Hello, …"
   - [x] 1.8 Nasadenie backendu na Railway ([postup](./setup/railway.md)): GitHub repo, Dockerfile, env premenné, verejná doména, health UP
   - [ ] 1.9 Nasadenie Flutter webu (statický hosting), CORS a Supabase Redirect URL na produkčnú doménu, naživo vidím „Hello, user"
2. **Doménové jadro** v Springu cez TDD: poradie pokrývania, pokrytie položiek, hranica základu, najbližší cieľ v hodinách, nepriradený zárobok.
3. **Záznam práce a prehľad plánu** vo Flutteri. Od tohto bodu aplikáciu reálne používam.
4. **Tvorba a úprava plánu** (nový plán ako kópia predošlého) a zoznam plánov vrátane minulých.
5. **1 až 2 okná zárabania** vlastného používania, zapisovanie postrehov.
6. **Uzavretá beta** s 5 až 15 živnostníkmi a rozhovory o cene.

## Rozsah prvého vydania (len pre mňa)

1. Prihlásenie (Supabase, Google alebo magic link)
2. Nastavenie hodinovej sadzby
3. Vytvorenie plánu: okno od–do, položky (názov, suma), zoradenie ťahaním, hranica základu
4. Záznam práce: dnešok jedným ťuknutím, ľubovoľný deň (doplnenie), úprava a zmazanie
5. Prehľad plánu: pokryté položky, rozpracovaná položka, najbližší cieľ v hodinách, nepriradený zárobok
6. Zoznam plánov vrátane minulých s nepokrytými položkami
7. Úprava plánu kedykoľvek počas okna

## Odložené

- Šablóna (zatiaľ kópia predošlého plánu)
- Upozornenie na chýbajúce dni
- Angličtina, ikony a farby položiek
- Natívne zostavenia do obchodov s aplikáciami
- Platby a verejná registrácia
- Notifikácie (zámerne žiadne)

## Monetizácia

- Hypotéza: freemium s predplatným. Jadro je zadarmo, platí sa za hĺbku: história a štatistiky, šablóny, viac súbežných plánov, sledovanie faktúr, export pre účtovníka.
- Do bety sa platby nestavajú. V bete sa overí ochota platiť (rozhovory, prípadne early-bird ponuka).
