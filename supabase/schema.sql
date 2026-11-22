-- Fatigue Curve · anonymous aggregate storage (Supabase / Postgres)
-- Run once in the Supabase SQL editor of a NEW project.
-- Design: anon may INSERT summary rows only; raw rows are never readable by anon.
-- Community stats come only from the security-definer function pvt_aggregate(),
-- which hides percentiles for any state with fewer than 20 samples.

create extension if not exists pgcrypto;

create table if not exists public.pvt_results (
  id             uuid primary key default gen_random_uuid(),
  created_at     timestamptz not null default now(),
  state          text not null check (state in ('day','post_night','sleep_deprived')),
  test_type      text not null check (test_type in ('pvt1_gng','pvt3_gng')),
  median_rt_ms   int  not null check (median_rt_ms between 100 and 30000),
  mean_rt_ms     int  not null check (mean_rt_ms   between 100 and 30000),
  lapses         int  not null check (lapses       between 0 and 300),
  false_starts   int  not null check (false_starts between 0 and 300),
  nogo_errors    int  not null check (nogo_errors  between 0 and 100),
  n_trials       int  not null check (n_trials     between 5 and 300),
  rt_hist        jsonb check (rt_hist is null or (
                    jsonb_typeof(rt_hist) = 'array'
                    and jsonb_array_length(rt_hist) <= 40
                    and pg_column_size(rt_hist) < 2000)),
  client_version text check (client_version is null or char_length(client_version) <= 20),
  constraint lapses_le_trials check (lapses <= n_trials)
);
-- No IP, name, email, device id or user id columns exist by design.

create index if not exists pvt_results_state_idx   on public.pvt_results (state);
create index if not exists pvt_results_created_idx on public.pvt_results (created_at);

alter table public.pvt_results enable row level security;

-- Lock everything down, then grant only column-level INSERT.
revoke all on public.pvt_results from anon, authenticated, public;
grant insert (state, test_type, median_rt_ms, mean_rt_ms, lapses, false_starts,
              nogo_errors, n_trials, rt_hist, client_version)
  on public.pvt_results to anon, authenticated;

drop policy if exists pvt_insert_anon on public.pvt_results;
create policy pvt_insert_anon on public.pvt_results
  for insert to anon, authenticated
  with check (true);           -- value checks enforced by CHECK constraints above
-- No SELECT / UPDATE / DELETE policies => those are denied for anon.

-- Crude global flood guard + server-side timestamp.
create or replace function public.pvt_before_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.pvt_results
        where created_at > now() - interval '1 minute') >= 30 then
    raise exception 'rate limit, try again later';
  end if;
  new.created_at := now();
  new.id := gen_random_uuid();
  return new;
end $$;
revoke all on function public.pvt_before_insert() from public, anon, authenticated;

drop trigger if exists pvt_before_insert on public.pvt_results;
create trigger pvt_before_insert before insert on public.pvt_results
  for each row execute function public.pvt_before_insert();

-- Aggregate-only read API.
create or replace function public.pvt_aggregate()
returns table (
  state            text,
  n                bigint,
  median_rt_p25    numeric,
  median_rt_p50    numeric,
  median_rt_p75    numeric,
  median_rt_deciles numeric[],
  lapses_per_min_p50 numeric,
  nogo_errors_p50  numeric
)
language sql stable security definer set search_path = public as $$
  with s(state) as (values ('day'), ('post_night'), ('sleep_deprived')),
  r as (
    select state, median_rt_ms, nogo_errors,
           lapses::numeric / case test_type when 'pvt1_gng' then 1 else 3 end as lpm
    from public.pvt_results
  )
  select s.state,
         count(r.state) as n,
         case when count(r.state) >= 20 then round(percentile_cont(0.25) within group (order by r.median_rt_ms)::numeric) end,
         case when count(r.state) >= 20 then round(percentile_cont(0.50) within group (order by r.median_rt_ms)::numeric) end,
         case when count(r.state) >= 20 then round(percentile_cont(0.75) within group (order by r.median_rt_ms)::numeric) end,
         case when count(r.state) >= 20 then
           (select array_agg(round(x::numeric)) from unnest(
              percentile_cont(array[0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9])
              within group (order by r.median_rt_ms)) as x) end,
         case when count(r.state) >= 20 then round(percentile_cont(0.5) within group (order by r.lpm)::numeric, 2) end,
         case when count(r.state) >= 20 then percentile_cont(0.5) within group (order by r.nogo_errors)::numeric end
  from s left join r on r.state = s.state
  group by s.state
  order by s.state;
$$;
revoke all on function public.pvt_aggregate() from public;
grant execute on function public.pvt_aggregate() to anon, authenticated;
