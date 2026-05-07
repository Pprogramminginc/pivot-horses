create table if not exists public.feedback_submissions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  email text not null default '',
  display_name text not null default '',
  category text not null default 'Feedback',
  message text not null,
  context jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists feedback_submissions_owner_created_idx
on public.feedback_submissions (owner_id, created_at desc);

create index if not exists feedback_submissions_category_created_idx
on public.feedback_submissions (category, created_at desc);

alter table public.feedback_submissions enable row level security;

drop policy if exists "feedback submissions owner only" on public.feedback_submissions;
create policy "feedback submissions owner only"
on public.feedback_submissions
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);
