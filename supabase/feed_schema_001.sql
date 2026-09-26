-- ===========================================================================
-- Feed-a-Paw — the whole data model, in one go (26 Sep 2026)
-- Family Supabase: bxoboypzumjdfkpszbkt (Sydney, Crafted Pixel Pro)
--
-- Everything Feed-a-Paw needs for M1 to M5 is created here: the team, the
-- trucks, the places fed, the rounds, the meat coming in, what was cooked,
-- where the truck is, the stories, the money the family raises, and the
-- settings that decide what the public sees.
--
-- FlutterFlow can only query Supabase's `public` schema, so every object lives
-- in `public` with a `feed_` prefix (the family convention agreed 26 Sep).
-- Nothing without that prefix is created or altered. Every table ships with
-- RLS and explicit grants here, and the file is safe to run twice.
--
-- The shared account table, `public.profiles`, belongs to Care-a-Paw: this
-- file only points at auth.users, never at profiles.
--
-- Then add yourself:  insert into public.feed_team (user_id, role, name)
--                     values ('<your auth uid>', 'lead', 'Ash');
-- ===========================================================================


-- ---------------------------------------------------------------------------
-- Housekeeping: one updated_at trigger used by every table that has the column
-- ---------------------------------------------------------------------------
create or replace function public.feed_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- ---------------------------------------------------------------------------
-- 1. The team: who is allowed to do what
-- ---------------------------------------------------------------------------
-- lead     runs the operation: starts and closes days, edits anything
-- driver   drives a truck and logs the round
-- feeder   a volunteer who feeds without a truck
-- writer   posts stories
create table if not exists public.feed_team (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  role       text not null check (role in ('lead','driver','feeder','writer')),
  name       text,
  phone      text,
  active     boolean not null default true,
  added_at   timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
drop trigger if exists feed_team_touch on public.feed_team;
create trigger feed_team_touch before update on public.feed_team
  for each row execute function public.feed_touch_updated_at();
alter table public.feed_team enable row level security;

create or replace function public.feed_has_role(wanted text[], uid uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.feed_team t
     where t.user_id = uid and t.active and t.role = any(wanted)
  );
$$;
create or replace function public.feed_is_team(uid uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select public.feed_has_role(array['lead','driver','feeder','writer'], uid);
$$;
create or replace function public.feed_is_lead(uid uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select public.feed_has_role(array['lead'], uid);
$$;

drop policy if exists feed_team_read on public.feed_team;
create policy feed_team_read on public.feed_team
  for select to authenticated using (public.feed_is_team() or user_id = auth.uid());
drop policy if exists feed_team_write on public.feed_team;
create policy feed_team_write on public.feed_team
  for all to authenticated using (public.feed_is_lead()) with check (public.feed_is_lead());

-- ---------------------------------------------------------------------------
-- 2. The trucks
-- ---------------------------------------------------------------------------
create table if not exists public.feed_trucks (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  plate       text,
  in_service  boolean not null default true,
  note        text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
drop trigger if exists feed_trucks_touch on public.feed_trucks;
create trigger feed_trucks_touch before update on public.feed_trucks
  for each row execute function public.feed_touch_updated_at();
alter table public.feed_trucks enable row level security;

drop policy if exists feed_trucks_read on public.feed_trucks;
create policy feed_trucks_read on public.feed_trucks for select to anon, authenticated using (true);
drop policy if exists feed_trucks_write on public.feed_trucks;
create policy feed_trucks_write on public.feed_trucks for all to authenticated
  using (public.feed_is_lead()) with check (public.feed_is_lead());

-- ---------------------------------------------------------------------------
-- 3. The places that get fed
-- ---------------------------------------------------------------------------
-- `source` says where a spot came from: typed in here, or copied from
-- Spot-a-Paw when the two databases are joined. `external_ref` is that app's
-- id, so a sync can run again without making duplicates.
-- `sensitive` hides the exact point from everyone but the team.
create table if not exists public.feed_spots (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  area          text,                       -- the neighbourhood, safe to show
  lat           double precision,
  lng           double precision,
  sensitive     boolean not null default true,
  typical_count int check (typical_count >= 0),
  needs         text[],                     -- food, water, shelter, medical
  note          text,
  source        text not null default 'local' check (source in ('local','spotapaw')),
  external_ref  text unique,
  active        boolean not null default true,
  created_by    uuid references auth.users(id) on delete set null,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists feed_spots_area on public.feed_spots (area);
drop trigger if exists feed_spots_touch on public.feed_spots;
create trigger feed_spots_touch before update on public.feed_spots
  for each row execute function public.feed_touch_updated_at();
alter table public.feed_spots enable row level security;

-- The public sees the area, never the point: the view below is what anon reads.
drop policy if exists feed_spots_read_team on public.feed_spots;
create policy feed_spots_read_team on public.feed_spots
  for select to authenticated using (public.feed_is_team());
drop policy if exists feed_spots_write on public.feed_spots;
create policy feed_spots_write on public.feed_spots for all to authenticated
  using (public.feed_has_role(array['lead','driver','feeder']))
  with check (public.feed_has_role(array['lead','driver','feeder']));

create or replace view public.feed_spots_public
with (security_invoker = off) as
  select id, name, area, active,
         case when sensitive then null else lat end as lat,
         case when sensitive then null else lng end as lng
    from public.feed_spots
   where active;

-- ---------------------------------------------------------------------------
-- 4. Routes: a round that repeats
-- ---------------------------------------------------------------------------
create table if not exists public.feed_routes (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  area        text,
  note        text,
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
drop trigger if exists feed_routes_touch on public.feed_routes;
create trigger feed_routes_touch before update on public.feed_routes
  for each row execute function public.feed_touch_updated_at();
alter table public.feed_routes enable row level security;

create table if not exists public.feed_route_spots (
  route_id   uuid not null references public.feed_routes(id) on delete cascade,
  spot_id    uuid not null references public.feed_spots(id) on delete cascade,
  position   int  not null default 0,
  primary key (route_id, spot_id)
);
alter table public.feed_route_spots enable row level security;

drop policy if exists feed_routes_read on public.feed_routes;
create policy feed_routes_read on public.feed_routes for select to authenticated using (public.feed_is_team());
drop policy if exists feed_routes_write on public.feed_routes;
create policy feed_routes_write on public.feed_routes for all to authenticated
  using (public.feed_has_role(array['lead','driver'])) with check (public.feed_has_role(array['lead','driver']));

drop policy if exists feed_route_spots_read on public.feed_route_spots;
create policy feed_route_spots_read on public.feed_route_spots for select to authenticated using (public.feed_is_team());
drop policy if exists feed_route_spots_write on public.feed_route_spots;
create policy feed_route_spots_write on public.feed_route_spots for all to authenticated
  using (public.feed_has_role(array['lead','driver'])) with check (public.feed_has_role(array['lead','driver']));

-- ---------------------------------------------------------------------------
-- 5. The butchers who give the meat
-- ---------------------------------------------------------------------------
create table if not exists public.feed_butchers (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  area        text,
  contact     text,
  note        text,
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
drop trigger if exists feed_butchers_touch on public.feed_butchers;
create trigger feed_butchers_touch before update on public.feed_butchers
  for each row execute function public.feed_touch_updated_at();
alter table public.feed_butchers enable row level security;

drop policy if exists feed_butchers_read on public.feed_butchers;
create policy feed_butchers_read on public.feed_butchers for select to authenticated using (public.feed_is_team());
drop policy if exists feed_butchers_write on public.feed_butchers;
create policy feed_butchers_write on public.feed_butchers for all to authenticated
  using (public.feed_has_role(array['lead','driver'])) with check (public.feed_has_role(array['lead','driver']));

-- ---------------------------------------------------------------------------
-- 6. A day's round
-- ---------------------------------------------------------------------------
create table if not exists public.feed_runs (
  id           uuid primary key default gen_random_uuid(),
  truck_id     uuid references public.feed_trucks(id) on delete set null,
  route_id     uuid references public.feed_routes(id) on delete set null,
  driver_id    uuid not null references auth.users(id) on delete restrict,
  day          date not null default (now() at time zone 'utc')::date,
  status       text not null default 'planned'
               check (status in ('planned','running','done','abandoned')),
  started_at   timestamptz,
  ended_at     timestamptz,
  distance_km  numeric(8,2) check (distance_km >= 0),
  fuel_cost    numeric(10,2) check (fuel_cost >= 0),
  currency     text not null default 'EGP',
  note         text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists feed_runs_day on public.feed_runs (day desc);
create index if not exists feed_runs_driver on public.feed_runs (driver_id, day desc);
drop trigger if exists feed_runs_touch on public.feed_runs;
create trigger feed_runs_touch before update on public.feed_runs
  for each row execute function public.feed_touch_updated_at();
alter table public.feed_runs enable row level security;

drop policy if exists feed_runs_read on public.feed_runs;
create policy feed_runs_read on public.feed_runs for select to anon, authenticated using (true);
drop policy if exists feed_runs_insert on public.feed_runs;
create policy feed_runs_insert on public.feed_runs for insert to authenticated
  with check (public.feed_has_role(array['lead','driver']) and driver_id = auth.uid());
drop policy if exists feed_runs_update on public.feed_runs;
create policy feed_runs_update on public.feed_runs for update to authenticated
  using (driver_id = auth.uid() or public.feed_is_lead())
  with check (driver_id = auth.uid() or public.feed_is_lead());
drop policy if exists feed_runs_delete on public.feed_runs;
create policy feed_runs_delete on public.feed_runs for delete to authenticated using (public.feed_is_lead());

-- ---------------------------------------------------------------------------
-- 7. What was cooked on board
-- ---------------------------------------------------------------------------
create table if not exists public.feed_batches (
  id           uuid primary key default gen_random_uuid(),
  run_id       uuid not null references public.feed_runs(id) on delete cascade,
  kilos        numeric(8,2) check (kilos > 0),
  started_at   timestamptz not null default now(),
  finished_at  timestamptz,
  note         text
);
create index if not exists feed_batches_run on public.feed_batches (run_id);
alter table public.feed_batches enable row level security;

drop policy if exists feed_batches_read on public.feed_batches;
create policy feed_batches_read on public.feed_batches for select to anon, authenticated using (true);
drop policy if exists feed_batches_write on public.feed_batches;
create policy feed_batches_write on public.feed_batches for all to authenticated
  using (exists (select 1 from public.feed_runs r where r.id = run_id
                  and (r.driver_id = auth.uid() or public.feed_is_lead())))
  with check (exists (select 1 from public.feed_runs r where r.id = run_id
                  and (r.driver_id = auth.uid() or public.feed_is_lead())));

-- ---------------------------------------------------------------------------
-- 8. Each stop on the round
-- ---------------------------------------------------------------------------
create table if not exists public.feed_run_stops (
  id             uuid primary key default gen_random_uuid(),
  run_id         uuid not null references public.feed_runs(id) on delete cascade,
  spot_id        uuid references public.feed_spots(id) on delete set null,
  position       int not null default 0,
  arrived_at     timestamptz,
  meals_served   int not null default 0 check (meals_served >= 0),
  animals_seen   int check (animals_seen >= 0),
  note           text,
  photo_path     text,
  skipped_reason text,
  lat            double precision,
  lng            double precision,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index if not exists feed_run_stops_run on public.feed_run_stops (run_id, position);
create index if not exists feed_run_stops_spot on public.feed_run_stops (spot_id);
drop trigger if exists feed_run_stops_touch on public.feed_run_stops;
create trigger feed_run_stops_touch before update on public.feed_run_stops
  for each row execute function public.feed_touch_updated_at();
alter table public.feed_run_stops enable row level security;

drop policy if exists feed_stops_read on public.feed_run_stops;
create policy feed_stops_read on public.feed_run_stops for select to anon, authenticated using (true);
drop policy if exists feed_stops_write on public.feed_run_stops;
create policy feed_stops_write on public.feed_run_stops for all to authenticated
  using (exists (select 1 from public.feed_runs r where r.id = run_id
                  and (r.driver_id = auth.uid() or public.feed_is_lead())))
  with check (exists (select 1 from public.feed_runs r where r.id = run_id
                  and (r.driver_id = auth.uid() or public.feed_is_lead())));

-- ---------------------------------------------------------------------------
-- 9. Feeds without a truck (volunteers), so the counter is the whole story
-- ---------------------------------------------------------------------------
create table if not exists public.feed_volunteer_feeds (
  id            uuid primary key default gen_random_uuid(),
  spot_id       uuid references public.feed_spots(id) on delete set null,
  fed_by        uuid not null references auth.users(id) on delete cascade,
  fed_at        timestamptz not null default now(),
  meals_served  int not null default 0 check (meals_served >= 0),
  animals_seen  int check (animals_seen >= 0),
  note          text,
  photo_path    text,
  source        text not null default 'local' check (source in ('local','spotapaw')),
  external_ref  text unique,
  created_at    timestamptz not null default now()
);
create index if not exists feed_vfeeds_when on public.feed_volunteer_feeds (fed_at desc);
alter table public.feed_volunteer_feeds enable row level security;

drop policy if exists feed_vfeeds_read on public.feed_volunteer_feeds;
create policy feed_vfeeds_read on public.feed_volunteer_feeds for select to anon, authenticated using (true);
drop policy if exists feed_vfeeds_insert on public.feed_volunteer_feeds;
create policy feed_vfeeds_insert on public.feed_volunteer_feeds for insert to authenticated
  with check (public.feed_is_team() and fed_by = auth.uid());
drop policy if exists feed_vfeeds_update on public.feed_volunteer_feeds;
create policy feed_vfeeds_update on public.feed_volunteer_feeds for update to authenticated
  using (fed_by = auth.uid() or public.feed_is_lead())
  with check (fed_by = auth.uid() or public.feed_is_lead());
drop policy if exists feed_vfeeds_delete on public.feed_volunteer_feeds;
create policy feed_vfeeds_delete on public.feed_volunteer_feeds for delete to authenticated
  using (fed_by = auth.uid() or public.feed_is_lead());

-- ---------------------------------------------------------------------------
-- 10. The meat coming in
-- ---------------------------------------------------------------------------
create table if not exists public.feed_collections (
  id            uuid primary key default gen_random_uuid(),
  run_id        uuid references public.feed_runs(id) on delete set null,
  butcher_id    uuid references public.feed_butchers(id) on delete set null,
  butcher_name  text,
  kilos         numeric(8,2) check (kilos > 0),
  collected_at  timestamptz not null default now(),
  collected_by  uuid references auth.users(id) on delete set null,
  photo_path    text,
  note          text,
  created_at    timestamptz not null default now()
);
create index if not exists feed_collections_when on public.feed_collections (collected_at desc);
alter table public.feed_collections enable row level security;

drop policy if exists feed_collections_read on public.feed_collections;
create policy feed_collections_read on public.feed_collections for select to anon, authenticated using (true);
drop policy if exists feed_collections_write on public.feed_collections;
create policy feed_collections_write on public.feed_collections for all to authenticated
  using (public.feed_has_role(array['lead','driver'])) with check (public.feed_has_role(array['lead','driver']));

-- ---------------------------------------------------------------------------
-- 11. Where the truck is (only while it runs)
-- ---------------------------------------------------------------------------
-- The app writes a ping every minute or so. What the public sees is decided by
-- public.feed_settings('live_truck'): 'off', 'area' or 'exact'.
create table if not exists public.feed_truck_pings (
  id        bigserial primary key,
  run_id    uuid not null references public.feed_runs(id) on delete cascade,
  at        timestamptz not null default now(),
  lat       double precision not null,
  lng       double precision not null,
  area      text
);
create index if not exists feed_pings_run on public.feed_truck_pings (run_id, at desc);
alter table public.feed_truck_pings enable row level security;

drop policy if exists feed_pings_read_team on public.feed_truck_pings;
create policy feed_pings_read_team on public.feed_truck_pings for select to authenticated using (public.feed_is_team());
drop policy if exists feed_pings_write on public.feed_truck_pings;
create policy feed_pings_write on public.feed_truck_pings for insert to authenticated
  with check (exists (select 1 from public.feed_runs r where r.id = run_id and r.driver_id = auth.uid()));

-- ---------------------------------------------------------------------------
-- 12. Stories from the street
-- ---------------------------------------------------------------------------
create table if not exists public.feed_stories (
  id            uuid primary key default gen_random_uuid(),
  title         text,
  words         text not null,
  photo_path    text,
  area          text,
  written_by    uuid references auth.users(id) on delete set null,
  published_at  timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists feed_stories_published on public.feed_stories (published_at desc);
drop trigger if exists feed_stories_touch on public.feed_stories;
create trigger feed_stories_touch before update on public.feed_stories
  for each row execute function public.feed_touch_updated_at();
alter table public.feed_stories enable row level security;

drop policy if exists feed_stories_read_public on public.feed_stories;
create policy feed_stories_read_public on public.feed_stories
  for select to anon, authenticated using (published_at is not null);
drop policy if exists feed_stories_read_team on public.feed_stories;
create policy feed_stories_read_team on public.feed_stories
  for select to authenticated using (public.feed_is_team());
drop policy if exists feed_stories_write on public.feed_stories;
create policy feed_stories_write on public.feed_stories for all to authenticated
  using (public.feed_has_role(array['lead','writer'])) with check (public.feed_has_role(array['lead','writer']));

-- ---------------------------------------------------------------------------
-- 13. The money: the truck fund, and what the other a-Paw apps send
-- ---------------------------------------------------------------------------
create table if not exists public.feed_fund (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,              -- "The first truck"
  target       numeric(12,2) not null check (target > 0),
  raised       numeric(12,2) not null default 0 check (raised >= 0),
  currency     text not null default 'USD',
  open         boolean not null default true,
  note         text,
  updated_at   timestamptz not null default now()
);
drop trigger if exists feed_fund_touch on public.feed_fund;
create trigger feed_fund_touch before update on public.feed_fund
  for each row execute function public.feed_touch_updated_at();
alter table public.feed_fund enable row level security;

drop policy if exists feed_fund_read on public.feed_fund;
create policy feed_fund_read on public.feed_fund for select to anon, authenticated using (true);
drop policy if exists feed_fund_write on public.feed_fund;
create policy feed_fund_write on public.feed_fund for all to authenticated
  using (public.feed_is_lead()) with check (public.feed_is_lead());

-- What each app sent, per month. Written by hand or by a job; read by everyone
-- so the same figure can show inside every a-Paw app.
create table if not exists public.feed_contributions (
  id           uuid primary key default gen_random_uuid(),
  app          text not null check (app in ('care','snap','track','mind','adopt','other')),
  period       date not null,              -- first day of the month
  amount       numeric(12,2) not null check (amount >= 0),
  currency     text not null default 'AUD',
  meals        int check (meals >= 0),     -- what it bought, once known
  note         text,
  created_at   timestamptz not null default now(),
  unique (app, period)
);
alter table public.feed_contributions enable row level security;

drop policy if exists feed_contributions_read on public.feed_contributions;
create policy feed_contributions_read on public.feed_contributions for select to anon, authenticated using (true);
drop policy if exists feed_contributions_write on public.feed_contributions;
create policy feed_contributions_write on public.feed_contributions for all to authenticated
  using (public.feed_is_lead()) with check (public.feed_is_lead());

-- ---------------------------------------------------------------------------
-- 14. Settings the app reads (no deploy needed to change them)
-- ---------------------------------------------------------------------------
create table if not exists public.feed_settings (
  key        text primary key,
  value      text not null,
  note       text,
  updated_at timestamptz not null default now()
);
drop trigger if exists feed_settings_touch on public.feed_settings;
create trigger feed_settings_touch before update on public.feed_settings
  for each row execute function public.feed_touch_updated_at();
alter table public.feed_settings enable row level security;

drop policy if exists feed_settings_read on public.feed_settings;
create policy feed_settings_read on public.feed_settings for select to anon, authenticated using (true);
drop policy if exists feed_settings_write on public.feed_settings;
create policy feed_settings_write on public.feed_settings for all to authenticated
  using (public.feed_is_lead()) with check (public.feed_is_lead());

insert into public.feed_settings (key, value, note) values
  ('live_truck', 'area', 'off | area | exact — what the public sees while a run is on'),
  ('support_url', 'https://onetailonemeal.com', 'where the Support button goes'),
  ('meals_per_kilo', '4', 'how many meals a kilo of trimmings makes, for estimates')
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- 15. What supporters see: one set of numbers
-- ---------------------------------------------------------------------------
create or replace view public.feed_meals_daily
with (security_invoker = off) as
  select d.day, sum(d.meals)::bigint as meals
    from (
      select r.day, coalesce(s.meals_served, 0) as meals
        from public.feed_runs r join public.feed_run_stops s on s.run_id = r.id
       where r.status = 'done'
      union all
      select (v.fed_at at time zone 'utc')::date as day, v.meals_served
        from public.feed_volunteer_feeds v
    ) d
   group by d.day;

create or replace view public.feed_totals
with (security_invoker = off) as
  select
    (select coalesce(sum(meals), 0) from public.feed_meals_daily)                      as meals_all_time,
    (select coalesce(sum(meals), 0) from public.feed_meals_daily
      where day = (now() at time zone 'utc')::date)                             as meals_today,
    (select coalesce(sum(meals), 0) from public.feed_meals_daily
      where day >= (now() at time zone 'utc')::date - 6)                        as meals_week,
    (select coalesce(sum(kilos), 0) from public.feed_collections)                      as kilos_collected,
    (select count(*) from public.feed_runs where status = 'done')                      as runs_done,
    (select count(*) from public.feed_spots where active)                              as spots_active;

-- Today's round, as much as is safe to show, honouring public.feed_settings.live_truck
create or replace view public.feed_truck_now
with (security_invoker = off) as
  select r.id as run_id,
         t.name as truck,
         r.started_at,
         case when (select value from public.feed_settings where key = 'live_truck') = 'exact'
              then p.lat end as lat,
         case when (select value from public.feed_settings where key = 'live_truck') = 'exact'
              then p.lng end as lng,
         case when (select value from public.feed_settings where key = 'live_truck') in ('exact','area')
              then p.area end as area,
         p.at as last_seen
    from public.feed_runs r
    left join public.feed_trucks t on t.id = r.truck_id
    left join lateral (
      select * from public.feed_truck_pings tp
       where tp.run_id = r.id order by tp.at desc limit 1
    ) p on true
   where r.status = 'running'
     and (select value from public.feed_settings where key = 'live_truck') <> 'off';

-- ---------------------------------------------------------------------------
-- 16. Photographs
-- ---------------------------------------------------------------------------
-- One public bucket for what supporters see; the app writes to it signed in.
insert into storage.buckets (id, name, public)
values ('feed-photos', 'feed-photos', true)
on conflict (id) do nothing;

drop policy if exists feed_photos_read on storage.objects;
create policy feed_photos_read on storage.objects
  for select to anon, authenticated using (bucket_id = 'feed-photos');
drop policy if exists feed_photos_write on storage.objects;
create policy feed_photos_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'feed-photos' and public.feed_is_team());
drop policy if exists feed_photos_manage on storage.objects;
create policy feed_photos_manage on storage.objects
  for update to authenticated using (bucket_id = 'feed-photos' and public.feed_is_team());
drop policy if exists feed_photos_delete on storage.objects;
create policy feed_photos_delete on storage.objects
  for delete to authenticated using (bucket_id = 'feed-photos' and public.feed_is_lead());

-- ---------------------------------------------------------------------------
-- 17. Grants — explicit, per table, as agreed
-- ---------------------------------------------------------------------------
grant select on
  public.feed_trucks, public.feed_runs, public.feed_run_stops, public.feed_batches, public.feed_collections,
  public.feed_volunteer_feeds, public.feed_stories, public.feed_fund, public.feed_contributions,
  public.feed_settings, public.feed_spots_public, public.feed_meals_daily, public.feed_totals, public.feed_truck_now
to anon;

grant select on
  public.feed_team, public.feed_trucks, public.feed_spots, public.feed_spots_public, public.feed_routes,
  public.feed_route_spots, public.feed_butchers, public.feed_runs, public.feed_batches, public.feed_run_stops,
  public.feed_volunteer_feeds, public.feed_collections, public.feed_truck_pings, public.feed_stories,
  public.feed_fund, public.feed_contributions, public.feed_settings, public.feed_meals_daily, public.feed_totals,
  public.feed_truck_now
to authenticated;

grant insert, update, delete on
  public.feed_team, public.feed_trucks, public.feed_spots, public.feed_routes, public.feed_route_spots,
  public.feed_butchers, public.feed_runs, public.feed_batches, public.feed_run_stops, public.feed_volunteer_feeds,
  public.feed_collections, public.feed_stories, public.feed_fund, public.feed_contributions, public.feed_settings
to authenticated;

grant insert on public.feed_truck_pings to authenticated;
grant usage, select on sequence public.feed_truck_pings_id_seq to authenticated;

grant execute on function public.feed_is_team(uuid), public.feed_is_lead(uuid),
                          public.feed_has_role(text[], uuid) to anon, authenticated;

-- Nothing is granted to future tables by default: each new one brings its own.
