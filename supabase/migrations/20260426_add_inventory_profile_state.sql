alter table public.profiles
add column if not exists inventory jsonb not null default '{}'::jsonb,
add column if not exists stable_expansion_tier integer not null default 0,
add column if not exists prenatal_boosted_pregnancy_ids jsonb not null default '[]'::jsonb,
add column if not exists carrot_boosted_horse_ids jsonb not null default '[]'::jsonb;

update public.profiles
set
  inventory = coalesce(inventory, '{}'::jsonb),
  stable_expansion_tier = coalesce(stable_expansion_tier, 0),
  prenatal_boosted_pregnancy_ids = coalesce(
    prenatal_boosted_pregnancy_ids,
    '[]'::jsonb
  ),
  carrot_boosted_horse_ids = coalesce(
    carrot_boosted_horse_ids,
    '[]'::jsonb
  );
