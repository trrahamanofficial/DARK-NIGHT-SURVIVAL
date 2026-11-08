-- DARK NIGHT: SURVIVAL — private Admin Dashboard schema
-- Run in Supabase SQL Editor. Never expose the service_role key in the browser.
-- Assumes public.profiles has id (uuid) and role (text), with role='admin' for approved admins.

create or replace function public.is_dark_night_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  );
$$;

revoke all on function public.is_dark_night_admin() from public;
grant execute on function public.is_dark_night_admin() to authenticated;

create table if not exists public.game_admin_settings (
  key text primary key check (length(key) between 2 and 80),
  value jsonb not null,
  updated_by uuid not null references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now()
);
alter table public.game_admin_settings enable row level security;
drop policy if exists "admin read game settings" on public.game_admin_settings;
drop policy if exists "admin insert game settings" on public.game_admin_settings;
drop policy if exists "admin update game settings" on public.game_admin_settings;
drop policy if exists "admin delete game settings" on public.game_admin_settings;
create policy "admin read game settings" on public.game_admin_settings for select to authenticated using ((select public.is_dark_night_admin()));
create policy "admin insert game settings" on public.game_admin_settings for insert to authenticated with check ((select public.is_dark_night_admin()) and updated_by = (select auth.uid()));
create policy "admin update game settings" on public.game_admin_settings for update to authenticated using ((select public.is_dark_night_admin())) with check ((select public.is_dark_night_admin()) and updated_by = (select auth.uid()));
create policy "admin delete game settings" on public.game_admin_settings for delete to authenticated using ((select public.is_dark_night_admin()));

create table if not exists public.admin_audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid not null references auth.users(id) on delete restrict,
  action text not null check (length(action) between 1 and 100),
  target text,
  created_at timestamptz not null default now()
);
alter table public.admin_audit_logs enable row level security;
drop policy if exists "admin read audit logs" on public.admin_audit_logs;
drop policy if exists "admin insert audit logs" on public.admin_audit_logs;
create policy "admin read audit logs" on public.admin_audit_logs for select to authenticated using ((select public.is_dark_night_admin()));
create policy "admin insert audit logs" on public.admin_audit_logs for insert to authenticated with check ((select public.is_dark_night_admin()) and actor_id = (select auth.uid()));
-- Intentionally no UPDATE or DELETE policy: audit records are append-only for clients.
