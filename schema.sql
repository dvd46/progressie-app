-- ══════════════════════════════════════════════════════
--  PROGRESSIE ANALYSE — DATABASE SCHEMA
--  Plak dit in Supabase > SQL Editor > New Query > Run
-- ══════════════════════════════════════════════════════

-- Coaches (worden aangemaakt via Supabase Auth)
-- De auth.users tabel wordt automatisch beheerd door Supabase

-- Coaches profiel (gekoppeld aan auth.users)
create table if not exists coaches (
  id uuid references auth.users(id) on delete cascade primary key,
  naam text not null,
  email text not null,
  organisatie text,
  created_at timestamptz default now()
);

-- Oefeningen (gedeeld door alle coaches)
create table if not exists oefeningen (
  id uuid default gen_random_uuid() primary key,
  naam text not null unique,
  foto text, -- base64 of URL
  lager_is_beter boolean default false,
  created_at timestamptz default now()
);

-- Klanten
create table if not exists klanten (
  id uuid default gen_random_uuid() primary key,
  coach_id uuid references coaches(id) on delete cascade,
  voornaam text not null,
  achternaam text,
  geboortedatum date,
  geslacht text,
  gewicht numeric,
  lengte numeric,
  email text,
  telefoon text,
  doelstelling text,
  medisch text,
  notities text,
  foto text, -- base64
  created_at timestamptz default now()
);

-- Metingen
create table if not exists metingen (
  id uuid default gen_random_uuid() primary key,
  klant_id uuid references klanten(id) on delete cascade,
  oefening_id uuid references oefeningen(id) on delete cascade,
  datum date not null,
  waarde numeric not null,
  created_at timestamptz default now(),
  unique(klant_id, oefening_id, datum)
);

-- Lifestyle enquêtes
create table if not exists lifestyle_enquetes (
  id uuid default gen_random_uuid() primary key,
  klant_id uuid references klanten(id) on delete cascade,
  datum date not null,
  data jsonb not null default '{}',
  created_at timestamptz default now(),
  unique(klant_id, datum)
);

-- Opmerkingen (welzijn)
create table if not exists opmerkingen (
  id uuid default gen_random_uuid() primary key,
  klant_id uuid references klanten(id) on delete cascade,
  datum date not null,
  slaap smallint check (slaap between 0 and 10),
  slaap_tekst text,
  stress smallint check (stress between 0 and 10),
  stress_tekst text,
  created_at timestamptz default now(),
  unique(klant_id, datum)
);

-- ── ROW LEVEL SECURITY ──────────────────────────────────────────────
-- Coaches zien alleen hun eigen klanten

alter table coaches enable row level security;
alter table klanten enable row level security;
alter table metingen enable row level security;
alter table opmerkingen enable row level security;
alter table lifestyle_enquetes enable row level security;
alter table oefeningen enable row level security;

-- Coaches: eigen rij lezen/schrijven
create policy "coaches_own" on coaches
  for all using (auth.uid() = id);

-- Coaches: alle coaches mogen de lijst van coaches lezen
create policy "coaches_read_all" on coaches
  for select using (auth.role() = 'authenticated');

-- Coaches: elke ingelogde coach mag andere coaches verwijderen
create policy "coaches_delete_any" on coaches
  for delete using (auth.role() = 'authenticated');

-- Oefeningen: iedereen ingelogd kan lezen/schrijven
create policy "oefeningen_read" on oefeningen
  for select using (auth.role() = 'authenticated');
create policy "oefeningen_write" on oefeningen
  for all using (auth.role() = 'authenticated');

-- Klanten: alle coaches mogen alle klanten lezen én aanpassen
create policy "klanten_coaches_all" on klanten
  for all using (
    exists (select 1 from coaches where coaches.id = auth.uid())
  );

-- Klanten: klant kan eigen rij lezen (op basis van e-mail)
create policy "klanten_self_read" on klanten
  for select using (email = auth.email());

-- Klanten: klant kan eigen rij updaten (eigen profiel bewerken)
create policy "klanten_self_update" on klanten
  for update using (email = auth.email());

-- Klanten: iedereen ingelogd mag leaderboard-deelnemers lezen (opt-in)
create policy "klanten_leaderboard_read" on klanten
  for select using (leaderboard_deelname = true and actief is not false);

-- Metingen: klant kan eigen metingen lezen
create policy "metingen_self_read" on metingen
  for select using (
    exists (
      select 1 from klanten
      where klanten.id = metingen.klant_id
      and klanten.email = auth.email()
    )
  );

-- Metingen: via klant eigenaar
create policy "metingen_own" on metingen
  for all using (
    exists (
      select 1 from klanten
      where klanten.id = metingen.klant_id
      and klanten.coach_id = auth.uid()
    )
  );

-- Metingen: leaderboard-deelnemers hun metingen zijn leesbaar voor iedereen ingelogd
create policy "metingen_leaderboard_read" on metingen
  for select using (
    exists (
      select 1 from klanten
      where klanten.id = metingen.klant_id
      and klanten.leaderboard_deelname = true
      and klanten.actief is not false
    )
  );

-- Opmerkingen: via klant eigenaar
create policy "opmerkingen_own" on opmerkingen
  for all using (
    exists (
      select 1 from klanten
      where klanten.id = opmerkingen.klant_id
      and klanten.coach_id = auth.uid()
    )
  );

-- Lifestyle enquêtes: coaches kunnen alles lezen/schrijven voor hun klanten
create policy "lifestyle_coaches_all" on lifestyle_enquetes
  for all using (
    exists (select 1 from coaches where coaches.id = auth.uid())
  );

-- Lifestyle enquêtes: klant kan eigen rijen lezen, invoegen, bijwerken en verwijderen
create policy "lifestyle_self_all" on lifestyle_enquetes
  for all using (
    exists (select 1 from klanten where klanten.id = lifestyle_enquetes.klant_id and klanten.email = auth.email())
  );

-- ── STANDAARD OEFENINGEN ────────────────────────────────────────────
insert into oefeningen (naam) values
  ('SLED PUSH (61 kg gestandardiseerd)'),
  ('Squat'),
  ('Bench Press'),
  ('Deadlift'),
  ('Pull-up'),
  ('Overhead Press')
on conflict (naam) do nothing;

-- ── AUTO-CREATE COACH PROFIEL BIJ REGISTRATIE ───────────────────────
create or replace function handle_new_user()
returns trigger as $$
begin
  -- Alleen als coach uitgenodigd: voeg toe als coach en verwijder uit whitelist
  if exists (select 1 from public.coach_emails where email = new.email) then
    insert into public.coaches (id, naam, email)
    values (
      new.id,
      coalesce(new.raw_user_meta_data->>'naam', split_part(new.email, '@', 1)),
      new.email
    );
    delete from public.coach_emails where email = new.email;
  end if;
  return new;
end;
$$ language plpgsql security definer;

-- ── LEADERBOARD FUNCTIES (SECURITY DEFINER = bypass RLS) ────────────
create or replace function get_leaderboard_klanten()
returns table(id uuid, voornaam text, achternaam text, foto text, geslacht text, leaderboard_deelname boolean, actief boolean)
security definer set search_path = public language sql as $$
  select id, voornaam, achternaam, foto, geslacht, leaderboard_deelname, actief
  from klanten where leaderboard_deelname = true and (actief is null or actief = true);
$$;

create or replace function get_leaderboard_metingen(oef_id uuid)
returns table(klant_id uuid, waarde numeric)
security definer set search_path = public language sql as $$
  select m.klant_id, m.waarde from metingen m
  join klanten k on k.id = m.klant_id
  where m.oefening_id = oef_id and k.leaderboard_deelname = true and (k.actief is null or k.actief = true);
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ── COACH BEHEER FUNCTIES ────────────────────────────────────────────

-- Verwijder auth-account volledig via ID (zodat herregistratie mogelijk is)
create or replace function delete_auth_user(user_id uuid)
returns void
security definer set search_path = public language plpgsql as $$
begin
  delete from auth.users where id = user_id;
end;
$$;

-- Verwijder auth-account via e-mail (voor klanten zonder gekend user_id)
create or replace function delete_auth_user_by_email(user_email text)
returns void
security definer set search_path = public language plpgsql as $$
begin
  delete from auth.users where email = user_email;
end;
$$;

-- Nodig coach uit of activeer direct als auth-account al bestaat
create or replace function invite_or_activate_coach(coach_email text)
returns text
security definer set search_path = public language plpgsql as $$
declare
  existing_user_id uuid;
begin
  select id into existing_user_id from auth.users where email = coach_email;
  if existing_user_id is not null then
    -- Auth-account bestaat al: maak coach-profiel direct aan
    insert into public.coaches (id, naam, email)
    values (existing_user_id, split_part(coach_email, '@', 1), coach_email)
    on conflict (id) do update set email = excluded.email, naam = coalesce(coaches.naam, excluded.naam);
    return 'activated';
  else
    -- Nog geen account: voeg toe aan whitelist zodat trigger hem oppikt
    insert into public.coach_emails (email) values (coach_email)
    on conflict (email) do nothing;
    return 'invited';
  end if;
end;
$$;
