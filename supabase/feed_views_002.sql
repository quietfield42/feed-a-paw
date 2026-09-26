-- Feed-a-Paw: what a driver has done so far today (27 Sep 2026)
-- Run after feed_schema.sql. Safe to run twice.
--
-- The app cannot add up rows by itself, so the database does it: one row per
-- round, with how many stops and how many meals.

create or replace view public.feed_run_totals
with (security_invoker = off) as
  select r.id                                   as run_id,
         r.driver_id,
         r.day,
         r.status,
         count(s.id)                            as stops,
         coalesce(sum(s.meals_served), 0)::int  as meals,
         coalesce(sum(s.animals_seen), 0)::int  as animals
    from public.feed_runs r
    left join public.feed_run_stops s on s.run_id = r.id
   group by r.id, r.driver_id, r.day, r.status;

grant select on public.feed_run_totals to anon, authenticated;

-- When each place was last fed, so a round can show what is overdue.
create or replace view public.feed_spot_last_fed
with (security_invoker = off) as
  select sp.id                     as spot_id,
         sp.name,
         sp.area,
         max(fed.at)               as last_fed_at
    from public.feed_spots sp
    left join (
      select spot_id, arrived_at as at from public.feed_run_stops
       where spot_id is not null
      union all
      select spot_id, fed_at as at from public.feed_volunteer_feeds
       where spot_id is not null
    ) fed on fed.spot_id = sp.id
   where sp.active
   group by sp.id, sp.name, sp.area;

grant select on public.feed_spot_last_fed to authenticated;
