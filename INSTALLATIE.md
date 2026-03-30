# 🚀 Progressie Analyse — Online zetten (stap voor stap)

Totale tijd: ±20 minuten. Geen technische kennis vereist.

---

## STAP 1 — Supabase account aanmaken (gratis database)

1. Ga naar https://supabase.com
2. Klik op **"Start your project"**
3. Maak een account aan (Google of e-mail)
4. Klik op **"New project"**
5. Geef het een naam: `progressie-analyse`
6. Kies een sterk wachtwoord (bewaar dit ergens)
7. Kies regio: **West EU (Frankfurt)** — dichtstbij België
8. Klik **"Create new project"** en wacht ±2 minuten

---

## STAP 2 — Database aanmaken

1. In je Supabase project, klik links op **"SQL Editor"**
2. Klik op **"New query"**
3. Open het bestand `schema.sql` (zit in dezelfde map als dit bestand)
4. Kopieer alle inhoud en plak het in het SQL venster
5. Klik op **"Run"** (groene knop rechtsonder)
6. Je ziet: *"Success. No rows returned"* — dat is goed!

---

## STAP 3 — Jouw gegevens invullen in de app

1. Ga in Supabase naar **Settings → API** (tandwiel icoontje linksonder)
2. Kopieer de **Project URL** (ziet eruit als `https://xxxx.supabase.co`)
3. Kopieer de **anon / public** key (lange string onder "Project API keys")
4. Open het bestand `public/index.html` in een teksteditor (bv. Kladblok of Notepad)
5. Zoek deze twee regels bovenaan (zoek naar `JOUW_SUPABASE`):
   ```
   const SUPABASE_URL = 'JOUW_SUPABASE_URL';
   const SUPABASE_KEY = 'JOUW_SUPABASE_ANON_KEY';
   ```
6. Vervang `JOUW_SUPABASE_URL` door jouw Project URL
7. Vervang `JOUW_SUPABASE_ANON_KEY` door jouw anon key
8. Sla het bestand op

---

## STAP 4 — Online zetten via Netlify (gratis hosting)

1. Ga naar https://netlify.com
2. Maak een gratis account aan
3. Klik op **"Add new site" → "Deploy manually"**
4. Sleep de **map `public`** (de map met `index.html`) naar het uploadvenster
5. Netlify geeft je een willekeurige URL zoals `https://amazing-name-123.netlify.app`
6. **Klaar!** Je app is online.

### Eigen domeinnaam (optioneel)
- In Netlify → Site settings → Domain management
- Voeg een eigen domein toe als je dat hebt

---

## STAP 5 — E-mail bevestiging uitzetten (aanbevolen voor intern gebruik)

Standaard stuurt Supabase een bevestigingsmail bij registratie.
Voor intern gebruik is dat vervelend. Zet het uit:

1. Supabase → **Authentication → Providers → Email**
2. Zet **"Confirm email"** uit
3. Opslaan

---

## STAP 6 — Coaches aanmaken

Elke coach maakt zelf een account aan via de app (knop "Registreren").
Of jij maakt accounts aan via:
**Supabase → Authentication → Users → "Invite user"**

---

## Updates uitrollen

Als je een nieuwe versie van `index.html` hebt:
1. Ga naar je site op Netlify
2. Klik op **"Deploys" → "Drag and drop"**
3. Sleep de `public` map opnieuw
4. Klaar — de app is direct bijgewerkt voor iedereen

---

## Samenvatting kosten

| Dienst | Gratis limiet | Meer dan genoeg voor? |
|--------|--------------|----------------------|
| Supabase | 500 MB database, 50.000 rijen | Ja, voor tientallen coaches en honderden klanten |
| Netlify | Onbeperkte hosting | Ja |

**Totaal: €0/maand**

---

## Hulp nodig?

Stuur de foutmelding door en ik help je verder.
