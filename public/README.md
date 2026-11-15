# Min Mis 🐾 (web-versionen)

Den oprindelige web-udgave af Whiskerling. Appen til nyere iPads ligger i roden af repoet.

En lille virtuel kat til den gamle iPad (iPad Air 1. generation, som højst kan køre iOS 12).
Spillet er en web-app. Den ligger som et ikon på hjemmeskærmen, kører i fuld skærm og virker uden internet.
iPad'en låses til spillet med **Guidet adgang**, så det ikke kræver noget jailbreak.

## Sådan spiller man

| Knap | Hvad sker der |
|---|---|
| 🍽️ **Mad** | Tørfoder, fisk eller rejer (godbid, højst 3 pr. kvarter). Katten går hen til skålen og spiser. |
| 🧶 **Leg** | Træk fjeren rundt med fingeren. Katten jagter den og hopper efter den. |
| 🧽 **Vask** | Skrub katten med svampen. Tryk på kattebakken for at fjerne efterladenskaberne. |
| 🌙 **Sov** | Slukker lyset. Katten går i sin kurv og sover, og den vågner af sig selv, når den er udhvilet. |
| 🎀 **Pynt** | Sløjfe, klokke, blomster, solbriller, hat, halstørklæde og krone låses op med hjerter. |

- **Stryg** over katten for at kæle (den spinder). **Tryk** på den, så siger den, hvad den mangler.
- Man får ❤️ ved at passe godt på katten. Der kommer også 3 hjerter hver dag, og 5, når den vokser.
- Tiden går, også når spillet er lukket. Fra kl. 20 til 7 sover katten, så den har det godt om morgenen.
- Efter en skoledag er katten sulten og lidt kedet, men den **dør aldrig**. Bliver den glemt, er den bare ked af det.
- Katten vokser: den er killing de første 2 dage, ung kat til dag 6 og derefter voksen kat.
- Uret på væggen viser det rigtige klokkeslæt, og himlen i vinduet følger tiden på dagen.

## Læg spillet på iPad'en

1. Start serveren på Mac'en fra projektmappen (mappen over `public/`):
   ```bash
   /usr/bin/python3 serve.py
   ```
   Brug `/usr/bin/python3` (Mac'ens egen Python). Den har allerede lov af firewallen til at tage imod forbindelser.
2. Sæt iPad'en på **samme wifi** som Mac'en, og åbn adressen, som serveren skriver ud, i Safari, fx
   `http://din-mac.local:8000/`. Virker den ikke, så prøv den, der står med tal, fx `http://192.168.1.20:8000/`.
3. Tryk på **Del-knappen** (firkanten med pilen), vælg **Føj til hjemmeskærm** og tryk **Tilføj**.
4. Åbn spillet **fra det nye ikon**. Katten i Safari og katten på ikonet er to forskellige katte.
5. Prøv at slå wifi fra og åbn spillet igen. Det skal stadig virke.

## Lås iPad'en til spillet (Guidet adgang)

1. **Indstillinger → Generelt → Tilgængelighed → Guidet adgang**, og slå det til.
2. Vælg **Adgangskodeindstillinger → Indstil kode til Guidet adgang**, og vælg en kode, som din datter ikke kender.
3. Under Guidet adgang kan du også vælge, hvornår skærmen skal slukke af sig selv.
4. Åbn Min Mis fra ikonet og **tryk tre gange hurtigt på hjemknappen**. Tryk derefter **Start** øverst til højre.
5. iPad'en kan nu kun vise spillet, også efter den har været låst. For at stoppe: tryk tre gange på hjemknappen, skriv koden og tryk **Afslut**.

Vil du gøre det grundigt, kan du først nulstille iPad'en (Indstillinger → Generelt → Nulstil → Slet alt indhold og alle indstillinger).
Sæt den op uden Apple-ID, læg spillet på hjemmeskærmen og flyt resten af apps'ene ind i en mappe på side 2.

**Lyd:** Kan man ikke høre noget, så tjek knappen på siden af iPad'en (lydløs) og lydstyrken.

## Forældremenu

Hold fingeren på **kattens navn** øverst til venstre i 2 sekunder og svar på regnestykket.
Her kan du slå lyd til og fra og starte forfra med en ny kat.

## Opdatér spillet

1. Ret i filerne i `public/`.
2. Ret versionsnummeret i `public/min-mis.appcache` (fx `version 1` til `version 2`). Ellers opdager iPad'en ikke ændringen.
3. Start serveren og åbn spillet på iPad'en på samme wifi. Den henter den nye version og genstarter spillet af sig selv. Katten og hjerterne bliver ved med at være der.

**Vigtigt:** Opdateringer skal komme fra præcis den adresse, spillet blev installeret fra.
Får Mac'en en anden IP-adresse, kan ikonet ikke finde opdateringen. Spillet virker stadig, men det bliver ikke opdateret.
Lægger du spillet på hjemmeskærmen igen fra en ny adresse, starter det med en ny, tom kat.
Vil du undgå det, så giv Mac'en en fast IP-adresse i routeren.

## Filer

| Fil | Indhold |
|---|---|
| `public/index.html` | Siden: knapper, menuer og layout |
| `public/game.js` | Hele spillet: katten, stuen, tiden, lyd (skrevet til Safari 12) |
| `public/min-mis.appcache` | Fortæller iPad'en, hvilke filer der skal gemmes til brug uden internet |
| `public/icon.png` | Hjemmeskærm-ikonet. Laves igen med `tools/make-icon.sh` |
| `serve.py` | Lille webserver, der kun bruges, når spillet installeres eller opdateres |

Test på Mac'en: åbn `http://localhost:8000/?debug`. Så kan `window.__minmis.step(sekunder)` i konsollen spole tiden frem.
