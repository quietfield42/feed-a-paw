-- ===========================================================================
-- Feed-a-Paw — tonight's route, with what has been fed (28 Sep 2026)
-- Run after feed_routes_003.sql. Safe to run twice.
--
-- The driver's screen can already show the places in order. What it cannot do
-- is say which ones are done, because that means joining the round's stops to
-- the route's places — and a phone in a truck should not be doing joins.
--
-- One view per round: every place on its route, in order, with the time it was
-- fed and how many meals, or nothing if it has not been reached yet.
-- ===========================================================================

create or replace view public.feed_tonight
with (security_invoker = on) as
  select r.id                                as run_id,
         r.driver_id,
         r.status                            as run_status,
         rp.route_id,
         rp.route_name,
         rp.position,
         rp.spot_id,
         rp.spot_name,
         rp.spot_area,
         rp.spot_note,
         p.fed_at,
         coalesce(p.meals, 0)                as meals,
         (p.fed_at is not null)              as done
    from public.feed_runs r
    join public.feed_route_plan rp on rp.route_id = r.route_id
    left join public.feed_run_progress p
           on p.run_id = r.id and p.spot_id = rp.spot_id;

grant select on public.feed_tonight to authenticated;

-- A round with no route falls out of that view entirely, which is right: there
-- is no list to tick off. The driver's screen keeps its plain stop button for
-- those, and for anything found on the way that is not on the route.
