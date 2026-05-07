create or replace function public.resolve_mating_session(target_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid := auth.uid();
  session_row public.mating_sessions%rowtype;
  pregnancy_row public.pregnancies%rowtype;
  outcome_record public.breeding_outcomes%rowtype;
  outcome_roll integer;
  outcome_type text;
  selected_payload jsonb;
begin
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into session_row
  from public.mating_sessions
  where id = target_session_id
    and owner_id = actor_id
  for update;

  if not found then
    raise exception 'Mating session not found';
  end if;

  if session_row.resolved_at is not null then
    return jsonb_build_object(
      'outcome_type', session_row.resolved_outcome,
      'pregnancy_id', (
        select pregnancy_id
        from public.breeding_outcomes
        where mating_session_id = session_row.id
        limit 1
      )
    );
  end if;

  if session_row.ends_at > timezone('utc', now()) then
    raise exception 'Mating session is still in progress';
  end if;

  outcome_roll := floor(random() * 100);
  if outcome_roll < 80 then
    outcome_type := 'pregnant';
    selected_payload := session_row.standard_pregnancy_payload;
  elsif outcome_roll < 90 then
    outcome_type := 'mutant';
    selected_payload := session_row.mutant_pregnancy_payload;
  else
    outcome_type := 'failed';
    selected_payload := null;
  end if;

  delete from public.breeding_cooldowns
  where owner_id = actor_id
    and horse_id = session_row.sire_id;

  insert into public.breeding_cooldowns (
    owner_id,
    horse_id,
    horse_name,
    sex,
    reason,
    ends_at
  )
  values (
    actor_id,
    session_row.sire_id,
    session_row.sire_name,
    'Stallion',
    'Sire recovery',
    timezone('utc', now()) + interval '12 hours'
  );

  if selected_payload is not null then
    insert into public.pregnancies (
      owner_id,
      dam_id,
      dam_name,
      sire_id,
      sire_name,
      unborn_foal_name,
      registry_id,
      breed,
      foal_payload,
      conceived_at,
      due_at,
      dam_cooldown_ends_at,
      sire_cooldown_ends_at,
      is_mutant
    )
    values (
      actor_id,
      session_row.dam_id,
      session_row.dam_name,
      session_row.sire_id,
      session_row.sire_name,
      coalesce(selected_payload ->> 'unbornFoalName', 'Reserved Foal'),
      coalesce(selected_payload ->> 'registryId', 'PENDING'),
      coalesce(selected_payload ->> 'breed', 'Horse'),
      coalesce(selected_payload -> 'foal', '{}'::jsonb),
      timezone('utc', now()),
      timezone('utc', now()) + interval '4 days',
      timezone('utc', now()) + interval '7 days',
      timezone('utc', now()) + interval '12 hours',
      coalesce((selected_payload ->> 'isMutant')::boolean, false)
    )
    returning *
    into pregnancy_row;
  end if;

  update public.mating_sessions
  set resolved_outcome = outcome_type,
      resolved_at = timezone('utc', now())
  where id = session_row.id;

  insert into public.breeding_outcomes (
    owner_id,
    mating_session_id,
    dam_id,
    sire_id,
    outcome_type,
    pregnancy_id,
    foal_registry_id,
    is_mutant
  )
  values (
    actor_id,
    session_row.id,
    session_row.dam_id,
    session_row.sire_id,
    outcome_type,
    pregnancy_row.id,
    pregnancy_row.registry_id,
    outcome_type = 'mutant'
  )
  returning *
  into outcome_record;

  return jsonb_build_object(
    'outcome_type', outcome_type,
    'pregnancy_id', pregnancy_row.id,
    'breeding_outcome_id', outcome_record.id
  );
end;
$$;

create or replace function public.deliver_pregnancy(target_pregnancy_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid := auth.uid();
  pregnancy_row public.pregnancies%rowtype;
  foal_payload jsonb;
  foal_row public.horses%rowtype;
  recovery_ends_at timestamptz;
begin
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into pregnancy_row
  from public.pregnancies
  where id = target_pregnancy_id
    and owner_id = actor_id
  for update;

  if not found then
    raise exception 'Pregnancy not found';
  end if;

  if pregnancy_row.delivered_at is not null then
    return jsonb_build_object(
      'horse_id', (
        select id
        from public.horses
        where owner_id = actor_id
          and registry_id = pregnancy_row.registry_id
        limit 1
      ),
      'registry_id', pregnancy_row.registry_id
    );
  end if;

  if pregnancy_row.due_at > timezone('utc', now()) then
    raise exception 'Pregnancy is not ready for delivery';
  end if;

  foal_payload := coalesce(pregnancy_row.foal_payload, '{}'::jsonb);

  insert into public.horses (
    owner_id,
    registry_id,
    registered_name,
    current_name,
    breed,
    sex,
    generation,
    age_days,
    breeding_retirement_days,
    starter_tier,
    price,
    transfer_count,
    is_mutant,
    is_public_listing,
    is_featured_profile_horse,
    is_listed_for_sale,
    genetic_profile,
    care_stats,
    lineage_memory,
    special_traits,
    dam_snapshot,
    sire_snapshot
  )
  values (
    actor_id,
    coalesce(foal_payload ->> 'registry_id', pregnancy_row.registry_id),
    coalesce(foal_payload ->> 'registered_name', pregnancy_row.unborn_foal_name),
    coalesce(foal_payload ->> 'current_name', pregnancy_row.unborn_foal_name),
    coalesce(foal_payload ->> 'breed', pregnancy_row.breed),
    coalesce(foal_payload ->> 'sex', 'Mare'),
    coalesce((foal_payload ->> 'generation')::integer, 1),
    greatest(coalesce((foal_payload ->> 'age_days')::integer, 1), 1),
    coalesce((foal_payload ->> 'breeding_retirement_days')::integer, 35),
    coalesce(foal_payload ->> 'starter_tier', 'basic'),
    coalesce((foal_payload ->> 'price')::integer, 0),
    coalesce((foal_payload ->> 'transfer_count')::integer, 0),
    coalesce((foal_payload ->> 'is_mutant')::boolean, false),
    false,
    false,
    false,
    coalesce(foal_payload -> 'genetic_profile', '{}'::jsonb),
    coalesce(foal_payload -> 'care_stats', '{}'::jsonb),
    coalesce(foal_payload -> 'lineage_memory', '{}'::jsonb),
    coalesce(foal_payload -> 'special_traits', '[]'::jsonb),
    foal_payload -> 'dam_snapshot',
    foal_payload -> 'sire_snapshot'
  )
  on conflict (registry_id) do update
  set owner_id = excluded.owner_id,
      current_name = excluded.current_name,
      age_days = excluded.age_days,
      updated_at = timezone('utc', now())
  returning *
  into foal_row;

  delete from public.horse_traits
  where horse_id = foal_row.id;

  insert into public.horse_traits (
    horse_id,
    trait_type,
    trait_option,
    rarity,
    sort_order
  )
  select
    foal_row.id,
    coalesce(trait_item ->> 'type', 'body_type'),
    coalesce(trait_item ->> 'option', 'Unknown'),
    coalesce(trait_item ->> 'rarity', 'common'),
    trait_index - 1
  from jsonb_array_elements(coalesce(foal_payload -> 'traits', '[]'::jsonb))
    with ordinality as traits(trait_item, trait_index);

  update public.pregnancies
  set delivered_at = timezone('utc', now())
  where id = pregnancy_row.id;

  delete from public.breeding_cooldowns
  where owner_id = actor_id
    and horse_id = pregnancy_row.dam_id;

  recovery_ends_at := pregnancy_row.due_at + interval '3 days';
  if recovery_ends_at > timezone('utc', now()) then
    insert into public.breeding_cooldowns (
      owner_id,
      horse_id,
      horse_name,
      sex,
      reason,
      ends_at
    )
    values (
      actor_id,
      pregnancy_row.dam_id,
      pregnancy_row.dam_name,
      'Mare',
      'Healing',
      recovery_ends_at
    );
  end if;

  return jsonb_build_object(
    'horse_id', foal_row.id,
    'registry_id', foal_row.registry_id,
    'recovery_ends_at', recovery_ends_at
  );
end;
$$;

grant execute on function public.resolve_mating_session(uuid) to authenticated;
grant execute on function public.deliver_pregnancy(uuid) to authenticated;
