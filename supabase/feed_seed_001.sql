-- Feed-a-Paw: enough content for the app to look alive (26 Sep 2026)
-- Run after feed_schema.sql. Safe to run twice.
--
-- Put your own auth uid in the first statement — Supabase → Authentication →
-- Users → copy the UUID of the account you sign in with.

-- 1. You, as the lead
insert into public.feed_team (user_id, role, name)
select id, 'lead', 'Ash'
  from auth.users
 where email = 'ash.elashiry@gmail.com'
on conflict (user_id) do update set role = 'lead', active = true;

-- 2. The truck fund, as it stands
insert into public.feed_fund (name, target, raised, currency, open, note)
select 'The first truck', 8000, 0, 'USD', true,
       'Vehicle, permits, fuel, a driver''s wage and three months of supplies.'
 where not exists (select 1 from public.feed_fund);

-- 3. The truck itself
insert into public.feed_trucks (name, plate, in_service, note)
select 'Truck one', null, true, 'Cooks on board in a sealed drum.'
 where not exists (select 1 from public.feed_trucks);

-- 4. A first round, so the map and the counter have shape
insert into public.feed_spots (name, area, sensitive, typical_count, needs, source)
select v.name, v.area, true, v.n, v.needs, 'local'
  from (values
    ('The bakery corner', 'Maadi',      8,  array['food','water']),
    ('Behind the mosque', 'Maadi',      5,  array['food']),
    ('The car park wall', 'Zamalek',   12,  array['food','medical']),
    ('The canal path',    'Dokki',      6,  array['food','water'])
  ) as v(name, area, n, needs)
 where not exists (select 1 from public.feed_spots);

-- 5. Two stories, so the page is not empty
insert into public.feed_stories (title, words, area, published_at)
select 'Nothing left behind',
       'The plates are made of vegetables, so the street is as clean when we '
       'leave as when we arrived. The dogs know the sound of the drum now.',
       'Maadi', now() - interval '2 days'
 where not exists (select 1 from public.feed_stories);

insert into public.feed_stories (title, words, area, published_at)
select 'The butcher on the corner',
       'He puts the trimmings aside before we ask. It is twenty kilos most '
       'mornings, and it would have gone in the bin.',
       'Dokki', now() - interval '6 hours'
 where (select count(*) from public.feed_stories) < 2;
