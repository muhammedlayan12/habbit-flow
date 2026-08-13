-- =====================================================================
-- HabitFlow — Supabase schema
-- Paste this entire file into Supabase Dashboard → SQL Editor → Run.
-- Safe to re-run: uses IF NOT EXISTS / OR REPLACE / DROP-then-CREATE
-- for policies and triggers so re-running during development won't
-- create duplicates or error out.
-- =====================================================================

create extension if not exists "pgcrypto";

-- =====================================================================
-- 1. PROFILES
-- =====================================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null default '',
  email text not null,
  avatar_url text,
  role text not null default 'user' check (role in ('user', 'admin')),
  is_active boolean not null default true,
  onboarding_complete boolean not null default false,
  productivity_goal text,
  wake_up_time text,
  sleep_time text,
  work_start_time text,
  work_end_time text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =====================================================================
-- 2. HABITS
-- =====================================================================
create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  description text not null default '',
  category text not null default 'General',
  icon text not null default 'check_circle_outline',
  color_index int not null default 0,
  frequency_type text not null default 'daily'
    check (frequency_type in ('daily', 'weekdays', 'weekends', 'custom')),
  frequency_days int[] not null default '{}',
  target_value int not null default 1,
  target_unit text not null default '1 time',
  reminder_enabled boolean not null default false,
  reminder_time time,
  start_date date not null default current_date,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_habits_user_id on public.habits (user_id);

-- =====================================================================
-- 3. HABIT COMPLETIONS
-- =====================================================================
create table if not exists public.habit_completions (
  id uuid primary key default gen_random_uuid(),
  habit_id uuid not null references public.habits (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  completion_date date not null,
  value int not null default 1,
  completed boolean not null default true,
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (habit_id, completion_date)
);

create index if not exists idx_habit_completions_user_id on public.habit_completions (user_id);
create index if not exists idx_habit_completions_habit_id on public.habit_completions (habit_id);
create index if not exists idx_habit_completions_date on public.habit_completions (completion_date);

-- =====================================================================
-- 4. ROUTINES
-- =====================================================================
create table if not exists public.routines (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  description text not null default '',
  routine_type text not null default 'General',
  start_time time not null default '07:00',
  color_index int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_routines_user_id on public.routines (user_id);

-- =====================================================================
-- 5. ROUTINE STEPS
-- =====================================================================
create table if not exists public.routine_steps (
  id uuid primary key default gen_random_uuid(),
  routine_id uuid not null references public.routines (id) on delete cascade,
  title text not null,
  notes text not null default '',
  duration_seconds int not null default 300,
  step_order int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_routine_steps_routine_id on public.routine_steps (routine_id);

-- =====================================================================
-- 6. ROUTINE COMPLETIONS (tracks each day a routine was finished)
-- =====================================================================
create table if not exists public.routine_completions (
  id uuid primary key default gen_random_uuid(),
  routine_id uuid not null references public.routines (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  completion_date date not null,
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (routine_id, completion_date)
);

create index if not exists idx_routine_completions_user_id on public.routine_completions (user_id);

-- =====================================================================
-- 7. TASKS
-- =====================================================================
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  description text not null default '',
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  category text not null default 'General',
  due_date date,
  due_time time,
  completed boolean not null default false,
  reminder_enabled boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_tasks_user_id on public.tasks (user_id);
create index if not exists idx_tasks_due_date on public.tasks (due_date);

-- =====================================================================
-- 8. FOCUS SESSIONS
-- =====================================================================
create table if not exists public.focus_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  duration_seconds int not null,
  completed boolean not null default false,
  label text,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_focus_sessions_user_id on public.focus_sessions (user_id);

-- =====================================================================
-- 9. USER PREFERENCES
-- =====================================================================
create table if not exists public.user_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  theme_mode text not null default 'system' check (theme_mode in ('light', 'dark', 'system')),
  notifications_enabled boolean not null default true,
  habit_reminders_enabled boolean not null default true,
  task_reminders_enabled boolean not null default true,
  routine_reminders_enabled boolean not null default true,
  time_format text not null default '12h' check (time_format in ('12h', '24h')),
  week_starts_on int not null default 1,
  day_start_time time not null default '07:00',
  day_end_time time not null default '21:00',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =====================================================================
-- 10. updated_at TRIGGER HELPER
-- =====================================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_habits_updated_at on public.habits;
create trigger trg_habits_updated_at
  before update on public.habits
  for each row execute function public.set_updated_at();

drop trigger if exists trg_routines_updated_at on public.routines;
create trigger trg_routines_updated_at
  before update on public.routines
  for each row execute function public.set_updated_at();

drop trigger if exists trg_routine_steps_updated_at on public.routine_steps;
create trigger trg_routine_steps_updated_at
  before update on public.routine_steps
  for each row execute function public.set_updated_at();

drop trigger if exists trg_tasks_updated_at on public.tasks;
create trigger trg_tasks_updated_at
  before update on public.tasks
  for each row execute function public.set_updated_at();

drop trigger if exists trg_user_preferences_updated_at on public.user_preferences;
create trigger trg_user_preferences_updated_at
  before update on public.user_preferences
  for each row execute function public.set_updated_at();

-- =====================================================================
-- 11. AUTO-CREATE PROFILE + PREFERENCES ON SIGNUP
-- =====================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.email, ''),
    'user'
  )
  on conflict (id) do nothing;

  insert into public.user_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =====================================================================
-- 12. is_admin() — SECURITY DEFINER helper so policies can check role
--     without causing infinite RLS recursion on public.profiles.
-- =====================================================================
create or replace function public.is_admin(check_uid uuid)
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles
    where id = check_uid and role = 'admin'
  );
$$;

-- =====================================================================
-- 13. Prevent users from self-promoting their own role.
--     Only an existing admin (checked via is_admin) may change role.
-- =====================================================================
create or replace function public.prevent_role_escalation()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if new.role is distinct from old.role then
    if not public.is_admin(auth.uid()) then
      new.role = old.role;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_prevent_role_escalation on public.profiles;
create trigger trg_prevent_role_escalation
  before update on public.profiles
  for each row execute function public.prevent_role_escalation();

-- =====================================================================
-- 14. ROW LEVEL SECURITY
-- =====================================================================
alter table public.profiles enable row level security;
alter table public.habits enable row level security;
alter table public.habit_completions enable row level security;
alter table public.routines enable row level security;
alter table public.routine_steps enable row level security;
alter table public.routine_completions enable row level security;
alter table public.tasks enable row level security;
alter table public.focus_sessions enable row level security;
alter table public.user_preferences enable row level security;

-- ---------- profiles ----------
drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin"
  on public.profiles for select
  using (auth.uid() = id or public.is_admin(auth.uid()));

drop policy if exists "profiles_update_own_or_admin" on public.profiles;
create policy "profiles_update_own_or_admin"
  on public.profiles for update
  using (auth.uid() = id or public.is_admin(auth.uid()))
  with check (auth.uid() = id or public.is_admin(auth.uid()));

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

-- ---------- habits ----------
drop policy if exists "habits_select_own_or_admin" on public.habits;
create policy "habits_select_own_or_admin"
  on public.habits for select
  using (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists "habits_insert_own" on public.habits;
create policy "habits_insert_own"
  on public.habits for insert
  with check (auth.uid() = user_id);

drop policy if exists "habits_update_own" on public.habits;
create policy "habits_update_own"
  on public.habits for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "habits_delete_own" on public.habits;
create policy "habits_delete_own"
  on public.habits for delete
  using (auth.uid() = user_id);

-- ---------- habit_completions ----------
drop policy if exists "habit_completions_select_own_or_admin" on public.habit_completions;
create policy "habit_completions_select_own_or_admin"
  on public.habit_completions for select
  using (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists "habit_completions_insert_own" on public.habit_completions;
create policy "habit_completions_insert_own"
  on public.habit_completions for insert
  with check (auth.uid() = user_id);

drop policy if exists "habit_completions_update_own" on public.habit_completions;
create policy "habit_completions_update_own"
  on public.habit_completions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "habit_completions_delete_own" on public.habit_completions;
create policy "habit_completions_delete_own"
  on public.habit_completions for delete
  using (auth.uid() = user_id);

-- ---------- routines ----------
drop policy if exists "routines_select_own_or_admin" on public.routines;
create policy "routines_select_own_or_admin"
  on public.routines for select
  using (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists "routines_insert_own" on public.routines;
create policy "routines_insert_own"
  on public.routines for insert
  with check (auth.uid() = user_id);

drop policy if exists "routines_update_own" on public.routines;
create policy "routines_update_own"
  on public.routines for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "routines_delete_own" on public.routines;
create policy "routines_delete_own"
  on public.routines for delete
  using (auth.uid() = user_id);

-- ---------- routine_steps (ownership via parent routine) ----------
drop policy if exists "routine_steps_select_own_or_admin" on public.routine_steps;
create policy "routine_steps_select_own_or_admin"
  on public.routine_steps for select
  using (
    exists (select 1 from public.routines r where r.id = routine_id and r.user_id = auth.uid())
    or public.is_admin(auth.uid())
  );

drop policy if exists "routine_steps_insert_own" on public.routine_steps;
create policy "routine_steps_insert_own"
  on public.routine_steps for insert
  with check (exists (select 1 from public.routines r where r.id = routine_id and r.user_id = auth.uid()));

drop policy if exists "routine_steps_update_own" on public.routine_steps;
create policy "routine_steps_update_own"
  on public.routine_steps for update
  using (exists (select 1 from public.routines r where r.id = routine_id and r.user_id = auth.uid()))
  with check (exists (select 1 from public.routines r where r.id = routine_id and r.user_id = auth.uid()));

drop policy if exists "routine_steps_delete_own" on public.routine_steps;
create policy "routine_steps_delete_own"
  on public.routine_steps for delete
  using (exists (select 1 from public.routines r where r.id = routine_id and r.user_id = auth.uid()));

-- ---------- routine_completions ----------
drop policy if exists "routine_completions_select_own_or_admin" on public.routine_completions;
create policy "routine_completions_select_own_or_admin"
  on public.routine_completions for select
  using (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists "routine_completions_insert_own" on public.routine_completions;
create policy "routine_completions_insert_own"
  on public.routine_completions for insert
  with check (auth.uid() = user_id);

drop policy if exists "routine_completions_delete_own" on public.routine_completions;
create policy "routine_completions_delete_own"
  on public.routine_completions for delete
  using (auth.uid() = user_id);

-- ---------- tasks ----------
drop policy if exists "tasks_select_own_or_admin" on public.tasks;
create policy "tasks_select_own_or_admin"
  on public.tasks for select
  using (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists "tasks_insert_own" on public.tasks;
create policy "tasks_insert_own"
  on public.tasks for insert
  with check (auth.uid() = user_id);

drop policy if exists "tasks_update_own" on public.tasks;
create policy "tasks_update_own"
  on public.tasks for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "tasks_delete_own" on public.tasks;
create policy "tasks_delete_own"
  on public.tasks for delete
  using (auth.uid() = user_id);

-- ---------- focus_sessions ----------
drop policy if exists "focus_sessions_select_own_or_admin" on public.focus_sessions;
create policy "focus_sessions_select_own_or_admin"
  on public.focus_sessions for select
  using (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists "focus_sessions_insert_own" on public.focus_sessions;
create policy "focus_sessions_insert_own"
  on public.focus_sessions for insert
  with check (auth.uid() = user_id);

drop policy if exists "focus_sessions_update_own" on public.focus_sessions;
create policy "focus_sessions_update_own"
  on public.focus_sessions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "focus_sessions_delete_own" on public.focus_sessions;
create policy "focus_sessions_delete_own"
  on public.focus_sessions for delete
  using (auth.uid() = user_id);

-- ---------- user_preferences ----------
drop policy if exists "user_preferences_select_own_or_admin" on public.user_preferences;
create policy "user_preferences_select_own_or_admin"
  on public.user_preferences for select
  using (auth.uid() = user_id or public.is_admin(auth.uid()));

drop policy if exists "user_preferences_insert_own" on public.user_preferences;
create policy "user_preferences_insert_own"
  on public.user_preferences for insert
  with check (auth.uid() = user_id);

drop policy if exists "user_preferences_update_own" on public.user_preferences;
create policy "user_preferences_update_own"
  on public.user_preferences for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =====================================================================
-- 15. OPTIONAL: promote the first admin.
-- Run this manually, once, from the SQL Editor after that person has
-- signed up through the app at least once (so their profile row exists).
-- Replace the email before running. This is a one-time manual dashboard
-- action — never expose an endpoint in the app that can do this.
-- =====================================================================
-- update public.profiles set role = 'admin' where email = 'you@example.com';

-- =====================================================================
-- Done. Tables, triggers, and RLS policies are ready.
-- =====================================================================
