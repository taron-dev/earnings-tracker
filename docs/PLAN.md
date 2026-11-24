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
   - [x] 1.9 Nasadenie Flutter webu na GitHub Pages ([postup](./setup/github-pages.md)): verejné repo, GitHub Actions, CORS a Supabase Redirect URL na produkčnú doménu, naživo vidím „Hello, user"
2. **Doménové jadro** v Springu cez TDD: poradie pokrývania, pokrytie položiek, hranica základu, najbližší cieľ v hodinách, nepriradený zárobok.
   Návrh podkrokov (upresniť pred začatím). Čistá doména bez Springu, databázy a REST, každý podkrok jeden TDD cyklus:
   - [x] 2.1 Hodnotové typy: suma peňazí (`BigDecimal` + `java.util.Currency`, zatiaľ EUR), hodiny, hodinová sadzba, okno zárabania (od–do)
     - `Money`: ≥ 0, normalizované na desatinné miesta meny, operácie medzi rôznymi menami vyhodia výnimku, `minus` nesmie ísť do mínusu
     - `WorkedTime`: celé minúty, ≥ 0, bez hornej hranice (`WorkLog` od 2.7 > 0)
     - `HourlyRate`: nad `Money`, > 0, `earningsFor(WorkedTime)` zaokrúhľuje `HALF_UP` na presnosť meny, `hoursToEarn(Money)` zaokrúhľuje nahor na celú minútu
     - `EarningWindow`: `LocalDate` od–do vrátane oboch, `from ≤ to`, `contains`, `overlaps`
     - balík `sk.taron.earningstracker.domain` bez Springu, `record`, JUnit 5 a AssertJ
   - [x] 2.2 Záznam práce a zárobok: hodiny × sadzba platná v čase záznamu, súčet zárobku za okno plánu
   - [x] 2.3 Poradie pokrývania a pokrytie položiek: zárobok napĺňa položky postupne, každú celú pred ďalšou; pokrytá, rozpracovaná, nepokrytá
   - [x] 2.4 Hranica základu: rozdelenie položiek na základ a extra, či je základ pokrytý
     - `Plan` drží `int essentialsCount`: prvých N položiek v poradí pokrývania je základ, zvyšok extra; povinný parameter konštruktora bez predvolenej hodnoty
     - `0 ≤ essentialsCount ≤ items.size()`, inak `IllegalArgumentException`
     - `essentials()` a `extras()` vracajú `List<BudgetItem>`; `ItemCoverage` a `coverageFor` sa nemenia
     - `isEssentialsCoveredBy(Money)`: zárobok ≥ súčet súm základu; prázdny základ je vždy pokrytý
     - chýbajúca suma či hodiny do základu zatiaľ nie (doplniť, keď ich bude UI potrebovať)
   - [x] 2.5 Najbližší cieľ: prvá nepokrytá položka, chýbajúce hodiny pri aktuálnej sadzbe (zaokrúhlenie nahor)
     - `Plan.nextMilestone(Money earnings, HourlyRate currentRate)` vracia `Optional<NextMilestone>`
     - `record NextMilestone(BudgetItem item, Money missing, WorkedTime timeNeeded)`: prvá nie pokrytá položka v poradí pokrývania, jej suma mínus pokryté, `currentRate.hoursToEarn(missing)`
     - prázdny aj plne pokrytý plán vracia `Optional.empty()`, bez rozlišovania
     - bez príznaku základ/extra (doplniť do `NextMilestone` v kroku 3, ak ho UI bude potrebovať)
     - iná mena sadzby, zárobku či položiek vyhodí `IllegalArgumentException`, kontrola vždy na vstupe
     - test zaokrúhlenia pri nepárnej sadzbe: `earningsFor(timeNeeded) ≥ missing`, o minútu menej už nestačí
   - [x] 2.6 Nepriradený zárobok: zárobok nad súčet všetkých položiek
     - `Plan.unassignedEarnings(Money earnings)` vracia `Money`: zárobok mínus súčet všetkých položiek, najmenej nula (`minusOrZero`)
     - kým zárobok nepresiahne súčet položiek, vracia nulu v mene zárobku
     - prázdny plán: celý zárobok je nepriradený
     - iná mena zárobku a položiek vyhodí `IllegalArgumentException` (pri prázdnom pláne nie je s čím porovnať)
     - verejný `total()` na `Plan` zatiaľ nie (doplniť, keď ho bude UI potrebovať)
   - [x] 2.7 Okrajové prípady: prázdny plán, nulový zárobok, zmena sadzby počas okna, záznamy mimo okna
     - pôvodné štyri prípady už pokryté testami, doplniť len `coverageFor` na prázdnom pláne (prázdny zoznam)
     - `Plan` bez vlastnej meny; konštruktor odmietne položky v rôznych menách (`IllegalArgumentException`)
     - `WorkLog` musí mať > 0 minút, inak `IllegalArgumentException`; `WorkedTime` ostáva ≥ 0
   - [x] 2.8 Perzistencia (Liquibase tabuľky, JPA) a REST API pre krok 3
     Spoločné pre všetky rezy ([ADR 0004](./adr/0004-persistence-and-api-conventions.md)). Každý rez obsahuje Liquibase, perzistenciu, REST, testy a vlastný commit:
     - JPA entity v samostatnom balíku, bez MapStruct; `EntityMapper<D, E>` (`toDomain(E)`, `from(D, UUID userId)`), implementácie `XyzEntityMapper` ako `@Component`
     - `UUID id` v `WorkLog` a `Plan` (UUIDv4 z aplikácie), nový objekt cez `create(...)`, kanonický konštruktor s id pre mapovač a testy; `BudgetItem` a `HourlyRate` bez id
     - `user_id` iba v DB (`uuid`, z `UUID.fromString(jwt.getSubject())`), do domény nejde
     - testy bez DB a bez nových závislostí: kontroléry s mockovanými službami, unit testy služieb a mapovačov; schému overí štart proti Supabase (`ddl-auto: validate`)
     - okná plánov jedného používateľa sa neprekrývajú: kontrola iba v aplikačnej službe cez `EarningWindow.overlaps` (pri úprave bez samotného plánu); v DB iba `NOT NULL`, bez exclusion constraintu a bez `CHECK` (zvážiť pred betou)
     - JSON: peniaze `{"amount": "123.45", "currency": "EUR"}` (suma ako reťazec), čas v celých minútach
     - sumy v DB `numeric(12,2)` + `currency char(3)`; API prijíma iba EUR (iná mena 400); na DTO `@Digits(integer = 10, fraction = 2)` pre všetky sumy
     - chyby ako `ProblemDetail` z jedného `@RestControllerAdvice`: `IllegalArgumentException` a Bean Validation 400, `NotFoundException` 404 (aj cudzí záznam), `OverlappingPlanException` 409, `HourlyRateNotSetException` 409 (typ `hourly-rate-not-set`)
     - zápis: `POST` 201 + `Location` + telo, `PUT` 200 + telo, `DELETE` 204, neexistujúci 404
     - [x] 2.8.1 Hodinová sadzba: `GET` / `PUT /api/hourly-rate`
       - tabuľka `hourly_rate(user_id uuid PK, amount, currency, updated_at)`, iba aktuálna sadzba, bez histórie
       - `PUT` robí upsert, telo aj odpoveď `{"perHour": {...}}`, 200
       - `GET` 200, alebo 404, keď sadzba nie je nastavená
     - [x] 2.8.2 Záznamy práce: `POST/GET/PUT/DELETE /api/work-logs`
       - tabuľka `work_log(id, user_id, day, minutes, rate_amount, rate_currency, created_at, updated_at)`, index (`user_id`, `day`)
       - `POST {"day", "minutes"}`: sadzbu doplní server z aktuálnej, bez sadzby 409
       - `PUT /{id}` mení iba deň a minúty, sadzba ostáva pôvodná
       - viac záznamov v jeden deň je povolených
       - 1 až 1440 minút: pravidlo v `WorkLog` aj `@Max(1440)` na DTO
       - `GET ?from&to`: povinné, oba dni vrátane, `from > to` 400, bez stránkovania, zoradené podľa `day` zostupne
       - položka odpovede `{"id", "day", "minutes", "hourlyRate", "earnings"}`; `GET /{id}` 200 alebo 404
     - [x] 2.8.3 Vytvorenie plánu: `POST /api/plans`, `GET /api/plans/{id}`
       - tabuľka `plan(id, user_id, window_from, window_to, essentials_count, created_at, updated_at)`, index (`user_id`, `window_from`)
       - tabuľka `budget_item(plan_id FK ON DELETE CASCADE, position, name, target_amount, target_currency)`, PK (`plan_id`, `position`); JPA `@ElementCollection` + `@Embeddable` + `@OrderColumn`
       - `POST {"window": {"from", "to"}, "items": [{"name", "target"}], "essentialsCount"}`, prázdny zoznam položiek povolený
       - prekrytie okien 409
       - `GET /{id}` v rovnakom tvare ako telo `POST` (cieľ `Location`), cudzí plán 404
     - [x] 2.8.4 Prehľad plánu: `GET /api/plans/current/overview?date=YYYY-MM-DD`
       - dátum je povinný a posiela ho klient (lokálny deň používateľa), server nepozná časové pásmo
       - žiadny plán neobsahuje dátum 404, sadzba nie je nastavená 409 `hourly-rate-not-set`
       - odpoveď: `planId`, `window`, `earnings`, `essentialsCovered`, `items[]` (`position`, `name`, `target`, `funded`, `state`, `essential`), `nextMilestone` (`position`, `missing`, `minutesNeeded`, alebo `null`), `unassignedEarnings`
       - záznamy práce v odpovedi nie sú (klient ich načíta cez `GET /api/work-logs` s oknom plánu)
       - prázdny plán: mena EUR
3. **Záznam práce a prehľad plánu** vo Flutteri. Od tohto bodu aplikáciu reálne používam.
   Spoločné pre všetky podkroky (každý má vlastný commit a testy):
   - sadzba má v kroku 3 vlastnú obrazovku
   - stav cez `flutter_riverpod` bez generovania kódu; po zápise `ref.invalidate` prehľadu aj zoznamu
   - modely s ručným `fromJson`/`toJson`, bez `json_serializable` a `build_runner`
   - `Money` ako `int minorUnits` + `int scale` (scale prečítaný z reťazca API), zaokrúhlenie `HALF_UP` ako na serveri, bez balíka `decimal`
   - `intl` + `flutter_localizations`, locale `sk`, týždeň od pondelka; sumy bez nulových centov (`750 €`, `262,50 €`)
   - testy: TDD na unit testy (`Money`, `fromJson`, počet dní), widget testy obrazoviek s falošným API cez `ProviderScope(overrides: ...)`
   - routing `StatefulShellRoute`: `/overview` a `/work-logs` so spodnou navigáciou, `/settings` samostatne, `/login`; `/` presmeruje na `/overview`
   - chyby: zlyhané načítanie ukáže „Skúsiť znova“, zlyhané uloženie nechá panel otvorený s hodnotami, 401 odhlási s hláškou „Prihlásenie vypršalo“
   - [x] 3.1 Základy: závislosti, locale `sk`, `ProviderScope`, `apiClient` ako provider; `Money` cez TDD (parsovanie, scale, náhľad zárobku z minút a sadzby s prípadmi z backendového `HourlyRateTest`, formát)
   - [x] 3.2 Kostra navigácie: `StatefulShellRoute` s prázdnymi `/overview` a `/work-logs`, spodná navigácia, `/settings` s účtom a odhlásením, 401 → `/login`; odstrániť `HomePage` („Hello, user“), backendový `/api/hello` ostáva
   - [x] 3.3 Hodinová sadzba: `GET`/`PUT /api/hourly-rate`, formulár v Nastaveniach s upozornením „Nová sadzba platí len pre práce zapísané odteraz“
   - [x] 3.4 Prehľad: `overview?date=` lokálny dnešok
     - hlavička: okno, „ešte N dní“ (počítané na klientovi), zarobené, sadzba malým písmom (ťuk → Nastavenia)
     - karta najbližšieho cieľa (položka, chýba €, h a min); plne pokrytý plán „Všetko pokryté ✓“, prázdny „Plán nemá položky“
     - položky s pruhom v sekciách ZÁKLAD (s príznakom pokrytý/nepokrytý) a EXTRA; nepriradený zárobok iba keď > 0
     - 409 `hourly-rate-not-set`: „Najprv nastav svoju hodinovú sadzbu“ + tlačidlo; 404: „Dnešok nepatrí do žiadneho plánu“ s vysvetlením, že práca sa započíta neskôr
   - [x] 3.5 Zoznam záznamov: okno aktuálneho plánu (bez listovania), súčet hodín a zárobku; bez plánu posledných 30 dní a hláška
   - [x] 3.6 Zápis práce: spodný panel, „+“ na oboch záložkách (bez sadzby vedie do Nastavení)
     - deň predvolený na dnes, ťuk otvorí kalendár; rýchle voľby 1, 2, 4, 6, 8 h; pole h a min
     - živý náhľad „= 260 € pri 40 €/h“; validácia 1 min až 24 h, inak Uložiť neaktívne
   - [x] 3.7 Úprava a zmazanie: ťuk na riadok otvorí ten istý panel s pôvodnou sadzbou záznamu; 🗑 s potvrdzovacím dialógom, bez „Späť“ (opätovný `POST` by zmenil sadzbu)
   - [x] 3.8 Nasadenie a začiatok používania: GitHub Pages, prvý reálny plán cez curl, sadzba v UI, prvý zápis naživo; hotové, keď sa na produkcii po zápise pohne najbližší cieľ
4. **Tvorba a úprava plánu** (nový plán ako kópia predošlého) a zoznam plánov vrátane minulých.
   Spoločné pre všetky podkroky (každý má vlastný commit a testy; pravidlá z kroku 3 platia ďalej):
   - backend pred Flutterom; o pokrytí rozhoduje iba server, klient doménu nepočíta
   - minulý plán (okno skončilo) je v UI iba na čítanie, backend to nevynucuje (o dnešku rozhoduje klient); zmazať sa dá aj minulý plán
   - okno sa pri úprave dá voľne meniť, jediné pravidlo je prekrytie s iným plánom (409), bez varovaní o vyradených záznamoch
   - po `POST`, `PUT` aj `DELETE` `ref.invalidate` zoznamu plánov aj Prehľadu
   - [x] 4.1 Backend `GET /api/plans`: zoznam s pokrytím
     - každý prvok v tvare `overview` bez najbližšieho cieľa: `planId`, `window`, `essentialsCount`, `earnings`, `essentialsCovered`, `items[]` (`position`, `name`, `target`, `funded`, `state`, `essential`), `unassignedEarnings`
     - nepotrebuje sadzbu (žiadne 409), zoradené podľa `window.from` zostupne, bez stránkovania
     - výpočet zdieľaný s `overview` (ten navyše pridá najbližší cieľ)
     - zárobok jedným dotazom na záznamy práce v rozsahu min–max okien, rozdelenie podľa okien v pamäti
     - `GET /api/plans/{id}` ostáva len ako cieľ `Location`, Flutter ho nepoužíva
   - [x] 4.2 Backend `PUT` a `DELETE /api/plans/{id}`
     - `PUT` telo rovnaké ako `POST`, nahradí celý plán (okno, `essentialsCount`, položky v poslanom poradí), 200 + tvar tela
     - prekrytie okna voči ostatným plánom používateľa (bez upravovaného) 409; cudzí alebo neexistujúci 404
     - `DELETE` 204, cudzí alebo neexistujúci 404; záznamy práce ostávajú
     - `@Size(max = 100)` na názve položky (iba DTO)
     - bez optimistickej zámky, vyhrá posledné uloženie
   - [x] 4.3 Záložka Plány (iba čítanie)
     - tretia záložka `/plans` v `StatefulShellRoute`: riadok „1. 10. – 31. 10. · 2 450 / 3 100 € · základ ✓ · 5 z 8“ (súhrn sčítaný z `items`)
     - detail `/plans/:id` z dát zoznamu: okno, zarobené, položky v sekciách ZÁKLAD a EXTRA s pruhmi, nepriradený zárobok iba keď > 0; bez najbližšieho cieľa a sadzby
     - plán nie je v zozname: „Plán neexistuje“ s odkazom na zoznam
     - ťuk na okno v hlavičke Prehľadu otvorí detail bežiaceho plánu
   - [x] 4.4 Nový plán: `/plans/new` na celú obrazovku, „+ Nový plán“ v záložke Plány
     - jeden `ReorderableListView` (ťahá sa za ☰), hranica základu je samostatný ťahateľný riadok; `essentialsCount` = počet položiek nad ňou
     - riadok „Názov · 450 €“, ťuk otvorí dialóg (názov, suma, 🗑 bez potvrdenia); „+ Pridať položku“ pridá na koniec (EXTRA)
     - validácia: názov povinný (orezaný, max. 100), suma > 0 v rozsahu `@Digits(10,2)`; prázdny zoznam aj duplicitné názvy povolené
     - predvyplnenie kópiou predošlého plánu (najneskorší `window.to`): iba položky so sumami, poradie a hranica, okno nie; okno je na začiatku prázdne („Vyber okno“) a Uložiť je neaktívne, kým ho nevyberiem; bez plánov prázdny formulár (TDD unit test)
     - chyby: zlyhané uloženie nechá formulár s hodnotami, 409 „Okno sa prekrýva s iným plánom“ pri okne; odchod s neuloženými zmenami „Zahodiť zmeny?“
     - Prehľad: pri 404 tlačidlo „Vytvoriť plán“, pri „Plán nemá položky“ tlačidlo „Pridať položky“ (úprava)
   - [x] 4.5 Úprava a zmazanie
     - `/plans/:id/edit` ten istý formulár s `PUT`, Upraviť iba pri bežiacom a budúcom pláne
     - 🗑 s potvrdzovacím dialógom pri každom pláne
   - [x] 4.6 Nasadenie: produkcia, odstrániť zmienky o curl (krok 3 a Známe obmedzenia), doplniť obmedzenie „minulý plán iba na čítanie len v UI“; hotové, keď na produkcii vytvorím ďalší plán kópiou bežiaceho, upravím bežiaci plán (napr. presuniem hranicu) a Prehľad zmenu ukáže
5. **Feedback z testovania**: úpravy podľa vlastného používania, podkroky budú postupne pribúdať.
   - [ ] 5.1 Rozloženie UI na telefóne
     - problém: Android, v Chrome v poriadku, po „Pridať na plochu“ (samostatné okno) je všetko veľmi malé a nedá sa priblížiť
     - prvý pokus: statický `<meta name="viewport">` v `web/index.html` (rovnaký obsah, aký vkladá Flutter až pri štarte); overiť na telefóne po nasadení, ikonu na ploche odstrániť a pridať znova
     - priblíženie gestom nie je cieľ (Flutter kreslí na canvas a gestá spracúva sám), aplikácia má mať čitateľnú veľkosť bez neho
     - hotové, keď je na telefóne text čitateľný a ovládacie prvky sa dajú pohodlne ťuknúť
   - [ ] 5.2 Najväčšia šírka na veľkej obrazovke
     - problém: na externom monitore sa aplikácia roztiahne na celú šírku
     - celá aplikácia v strede v stĺpci najviac 600 dp (koniec Material 3 triedy „compact“, šírka telefónu), okraje vo farbe `surfaceContainerHighest`
     - obmedzenie cez `MaterialApp.router(builder:)`, takže dialógy a spodné panely ostanú v stĺpci; bez `NavigationRail` a viacstĺpcového rozloženia
     - hotové, keď na monitore vyzerá aplikácia ako na telefóne v strede obrazovky
   - [ ] 5.3 Tlačidlo „+“ prekrýva stav položiek
     - problém: pri veľa položkách v Prehľade „+“ (FAB) zakryje sumu „zarobené / cieľ“ v poslednom riadku; zoznam má dole iba 16 px, takže sa spod tlačidla nedá vyrolovať
     - riešenie: spodné odsadenie zoznamu `fabClearance` = 88 (56 tlačidlo + 2 × 16), aby sa posledný riadok dal vyrolovať nad tlačidlo; Prehľad, Záznamy aj Plány (tie ho už mali)
     - zvážené a zatiaľ nie: schovanie tlačidla pri rolovaní, tlačidlo v spodnej lište, „+“ v hornej lište, suma pod názvom položky
     - hotové, keď sa na telefóne pri dlhom pláne dá prečítať suma poslednej položky
6. **1 až 2 okná zárabania** vlastného používania, zapisovanie postrehov.
7. **Uzavretá beta** s 5 až 15 živnostníkmi a rozhovory o cene.

## Rozsah prvého vydania (len pre mňa)

1. Prihlásenie (Supabase, Google alebo magic link)
2. Nastavenie hodinovej sadzby
3. Vytvorenie plánu: okno od–do, položky (názov, suma), zoradenie ťahaním, hranica základu
4. Záznam práce: dnešok jedným ťuknutím, ľubovoľný deň (doplnenie), úprava a zmazanie
5. Prehľad plánu: pokryté položky, rozpracovaná položka, najbližší cieľ v hodinách, nepriradený zárobok
6. Zoznam plánov vrátane minulých s nepokrytými položkami
7. Úprava plánu kedykoľvek počas okna

## Známe obmedzenia

Vedome ponechané, opraviť, keď začnú prekážať:

- „Dnešok“ (`todayProvider`) sa určí pri načítaní; aplikácia otvorená cez polnoc ukazuje včerajší deň, kým ju neobnovím
- Nastavenia sa otvárajú cez `context.push`, takže URL v prehliadači ostane `/overview`; F5 v Nastaveniach vráti na Prehľad (`GoRouter.optionURLReflectsImperativeAPIs` by to zmenil)
- Flutter kód nemá jednotnú šírku riadkov: nové súbory po `dart format` majú 80 znakov, staršie dlhšie; zjednotiť nastavením `formatter: page_width` v `analysis_options.yaml`
- Widget testy bežia bez slovenskej lokalizácie, slovenský kalendár (týždeň od pondelka) je overený len ručne na produkcii
- Minulý plán (okno skončilo) je iba na čítanie len v UI; backend `PUT /api/plans/{id}` prijme úpravu akéhokoľvek vlastného plánu, lebo nepozná dnešok používateľa

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
