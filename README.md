# HabitFlow

A polished, production-quality Flutter habit tracker and daily-routine app —
habits, routines with a step-by-step timer, tasks, focus sessions,
statistics, and a role-protected admin dashboard, all backed by Supabase
(Postgres + Auth + Row Level Security).

**Designed & Developed by Muhammad Layan**
Portfolio: https://muhammadlayan.vercel.app/

---

## Features

- **Auth** — email/password signup & login via Supabase Auth, real
  email-based password reset, session persistence, logout.
- **Onboarding** — goal, wake/sleep time, work hours, starter habits.
- **Dashboard** — today's progress ring, today's habits, today's schedule
  (routines + due tasks merged by time), quick actions.
- **Habits** — create/edit/pause/delete, custom frequency (daily / weekdays
  / weekends / custom days), reminders, real streak & completion-rate math
  computed from actual completion history (never faked), weekly bar chart,
  calendar history.
- **Routines** — ordered steps with drag-to-reorder, a real per-step
  countdown timer that auto-advances, pause/resume/skip/finish, completion
  screen.
- **Tasks** — priority, due date/time, reminders, Today / Upcoming /
  Completed tabs, swipe-to-delete.
- **Focus Mode** — 15/25/45/60-minute or custom countdown, pause/resume/
  reset/finish-early, sessions saved to Supabase.
- **Statistics** — productivity score, daily/weekly completion, streaks,
  tasks/routines/focus rollups, weekly bar chart, achievement badges.
- **Profile & Settings** — edit profile, change password, notification
  toggles, theme (light/dark/system), week-start day, time format, About
  section with the developer credit above.
- **Admin dashboard** (role-protected) — platform-wide user count, habit/
  task/routine/focus stats, user management (search/filter/activate/
  deactivate), most-popular habits & routines analytics.
- Local notifications for habit/task reminders (permission failures never
  crash the app — they degrade gracefully).
- Responsive layouts, empty states, loading states, confirmation dialogs,
  pull-to-refresh throughout.

## Tech Stack

- Flutter / Dart, Material 3
- Supabase (PostgreSQL, Auth, Row Level Security)
- `provider` for state management
- `fl_chart` for charts, `table_calendar` for the habit history calendar
- `flutter_local_notifications` for reminders

---

## Setup

### 1. Install Flutter

Install the Flutter SDK (stable channel) — see https://docs.flutter.dev/get-started/install.

### 2. Generate native platform folders

This source drop ships **`lib/`, `pubspec.yaml`, and the Supabase SQL** —
the native `android/` and `ios/` wrapper folders aren't included (they
contain machine-generated/binary files that don't belong in a hand-edited
source drop). Generate them once, from inside the unzipped project folder:

```bash
flutter create .
```

This safely scaffolds `android/`, `ios/`, and related files without
touching `lib/` or the dependency list already in `pubspec.yaml`.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Configure Supabase

A working `.env` is already included in this project pointing at the
Supabase project you provided, so it will run out of the box. To point it
at your **own** Supabase project instead:

1. Copy `.env.example` to `.env`.
2. Fill in your project's values from **Supabase Dashboard → Project
   Settings → API**:
   ```env
   SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
   SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY
   ```
   Only ever use the **anon / publishable** key here — never the
   `service_role` key. The anon key is safe to ship in a client app because
   every table is protected by Row Level Security (see below).

### 5. Run the SQL schema

Open **Supabase Dashboard → SQL Editor**, paste the entire contents of
`supabase_schema.sql`, and run it. This creates every table, index,
trigger, and RLS policy the app needs. It's safe to re-run (it drops and
recreates policies/triggers instead of erroring on duplicates).

### 6. Run

```bash
flutter run
```

### 7. Build a release APK

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

> Note: this sandbox environment has no Flutter SDK and no access to
> pub.dev, so I could not run `flutter pub get`, `flutter analyze`, or
> build the APK myself here. Please run the commands above locally and
> let me know if the analyzer flags anything — happy to fix it.

---

## Supabase Setup Details

`supabase_schema.sql` creates:

- `profiles`, `habits`, `habit_completions`, `routines`, `routine_steps`,
  `routine_completions`, `tasks`, `focus_sessions`, `user_preferences`.
- A trigger that auto-creates a `profiles` + `user_preferences` row the
  moment someone signs up through Supabase Auth.
- Row Level Security on every table: users can only read/write their own
  rows (`auth.uid() = user_id`), enforced at the Postgres level — not by
  client-side filtering.
- An `is_admin()` SECURITY DEFINER function admins' policies use to read
  across all users' data for the admin dashboard, without causing RLS
  recursion.
- A trigger that blocks a user from promoting their own `role` column —
  only an existing admin can change someone's role, and there is no
  in-app way to self-escalate.

## Admin Setup

There's no seeded admin account and no in-app way to become one — that's
intentional. To make a user an admin:

1. Have that person sign up through the app normally (this creates their
   `profiles` row via the trigger).
2. In **Supabase Dashboard → SQL Editor**, run:
   ```sql
   update public.profiles set role = 'admin' where email = 'their@email.com';
   ```
3. They'll see the **Admin Dashboard** entry on their Profile tab next time
   they log in (or refresh).

## Project Structure

```
lib/
  core/
    config/      # env loading + Supabase client bootstrap
    theme/       # colors, Material 3 theme
    utils/       # date helpers
  models/        # Habit, Routine, TaskItem, FocusSession, AppUser, ...
  providers/     # AuthProvider, HabitProvider, RoutineProvider,
                 # TaskProvider, FocusProvider — all Supabase-backed
  services/      # notifications, demo-data seeding
  widgets/       # reusable buttons, cards, list tiles, empty/loading states
  features/
    auth/        # splash, login, signup, forgot-password, onboarding
    main/        # bottom-nav shell
    dashboard/   # home screen
    habits/      # list, create/edit, details + analytics
    routines/    # list, create/edit (reorderable steps), timer
    tasks/       # list, create/edit
    focus/       # focus timer
    statistics/  # charts + achievements
    profile/     # profile, edit profile, settings
    admin/       # dashboard, user management, content analytics
supabase_schema.sql   # paste into Supabase SQL Editor
.env / .env.example
```

## Removing Demo Data

New accounts are seeded with a handful of sample habits/tasks/routines so
the app doesn't feel empty on first login. To ship without this, stop
calling `SeedService.seedForNewUser(...)` from
`lib/features/auth/onboarding_screen.dart` — nothing else needs to change.
