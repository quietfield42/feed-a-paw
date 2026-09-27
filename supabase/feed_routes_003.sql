-- ===========================================================================
-- Feed-a-Paw — a round follows a route (27 Sep 2026)
-- Run after feed_schema_001.sql and feed_views_002.sql. Safe to run twice.
--
-- Ash's decision, 27 Sep: the truck drivers work to a route — an ordered run
-- of feeding places — and the idea is Spot-a-Paw's, adopted for the trucks.
-- `feed_routes` and `feed_route_spots` were already created by the schema;
-- what was missing is the link from a round to the route it followed, and a
-- way to read a route's stops in order with the places' names attached.
-- ===========================================================================

-- A round now remembers which route it followed. Nullable, because a round
-- can still be driven off the cuff, and every round driven so far was.
alter table public.feed_runs
  add column if not exists route_id uuid references public.feed_routes (id);

create index if not exists feed_runs_route_idx on public.feed_runs (route_id);


-- A route's stops, in order, with the place's name and area — what the
-- driver's screen actually needs, so the app does not join anything itself.
create or replace view public.feed_route_plan
with (security_invoker = on) as
  select rs.route_id,
         r.name        as route_name,
         r.area        as route_area,
         rs.position,
         sp.id         as spot_id,
         sp.name       as spot_name,
         sp.area       as spot_area,
         sp.note       as spot_note
    from public.feed_route_spots rs
    join public.feed_routes r on r.id = rs.route_id
    join public.feed_spots  sp on sp.id = rs.spot_id
   where r.active and sp.active
   order by rs.route_id, rs.position;

grant select on public.feed_route_plan to authenticated;


-- Which stops on tonight's route have already been fed, so the driver can
-- tick them off rather than remember.
create or replace view public.feed_run_progress
with (security_invoker = on) as
  select s.run_id,
         s.spot_id,
         min(s.arrived_at) as fed_at,
         sum(s.meals_served)::int as meals
    from public.feed_run_stops s
   where s.spot_id is not null
   group by s.run_id, s.spot_id;

grant select on public.feed_run_progress to authenticated;


-- Two routes to drive, built from the places already seeded. Skipped quietly
-- if the spots are not there.
insert into public.feed_routes (id, name, area, note)
values
  ('33333333-3333-4333-8333-333333333333', 'Maadi evening', 'Maadi',
   'The usual evening run: the corniche end first, then back through the side streets.'),
  ('44444444-4444-4444-8444-444444444444', 'Zamalek late', 'Zamalek',
   'Later, after the restaurants put their bins out.')
on conflict (id) do nothing;

insert into public.feed_route_spots (route_id, spot_id, position)
select '33333333-3333-4333-8333-333333333333', sp.id,
       row_number() over (order by sp.name)
  from public.feed_spots sp
 where sp.active and sp.area ilike '%maadi%'
on conflict (route_id, spot_id) do nothing;

insert into public.feed_route_spots (route_id, spot_id, position)
select '44444444-4444-4444-8444-444444444444', sp.id,
       row_number() over (order by sp.name)
  from public.feed_spots sp
 where sp.active and sp.area ilike '%zamalek%'
on conflict (route_id, spot_id) do nothing;

-- If neither route picked up any stops, the seeded places use different area
-- names. See what they are:
--   select distinct area from public.feed_spots where active;
