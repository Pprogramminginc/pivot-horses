create or replace function public.grant_verified_coin_purchase(
  target_owner_id uuid,
  target_product_id text,
  target_transaction_id text,
  target_platform text default 'ios',
  target_raw_receipt_hash text default null,
  verification_context jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  pack_row public.coin_packs%rowtype;
  receipt_row public.purchase_receipts%rowtype;
  next_balance integer;
begin
  select *
  into pack_row
  from public.coin_packs
  where product_id = target_product_id
    and is_active;

  if not found then
    raise exception 'Unknown or inactive coin pack';
  end if;

  select *
  into receipt_row
  from public.purchase_receipts
  where platform = target_platform
    and transaction_id = target_transaction_id
  for update;

  if found then
    if receipt_row.owner_id <> target_owner_id then
      raise exception 'Purchase transaction belongs to another owner';
    end if;

    if receipt_row.product_id <> target_product_id then
      raise exception 'Purchase transaction product mismatch';
    end if;

    if receipt_row.status = 'verified' then
      select coin_balance
      into next_balance
      from public.profiles
      where id = target_owner_id;

      return jsonb_build_object(
        'already_processed', true,
        'coin_amount', pack_row.coin_amount,
        'coin_balance', next_balance,
        'receipt_id', receipt_row.id
      );
    end if;

    update public.purchase_receipts
    set
      status = 'verified',
      purchased_amount = pack_row.coin_amount,
      price_cents = pack_row.price_cents,
      currency = pack_row.currency,
      raw_receipt_hash = target_raw_receipt_hash,
      context = coalesce(context, '{}'::jsonb) || coalesce(verification_context, '{}'::jsonb),
      verified_at = timezone('utc', now())
    where id = receipt_row.id
    returning *
    into receipt_row;
  else
    insert into public.purchase_receipts (
      owner_id,
      platform,
      product_id,
      transaction_id,
      status,
      purchased_amount,
      price_cents,
      currency,
      raw_receipt_hash,
      context,
      verified_at
    )
    values (
      target_owner_id,
      target_platform,
      target_product_id,
      target_transaction_id,
      'verified',
      pack_row.coin_amount,
      pack_row.price_cents,
      pack_row.currency,
      target_raw_receipt_hash,
      coalesce(verification_context, '{}'::jsonb),
      timezone('utc', now())
    )
    returning *
    into receipt_row;
  end if;

  update public.profiles
  set
    coin_balance = coin_balance + pack_row.coin_amount,
    updated_at = timezone('utc', now())
  where id = target_owner_id
  returning coin_balance
  into next_balance;

  return jsonb_build_object(
    'already_processed', false,
    'coin_amount', pack_row.coin_amount,
    'coin_balance', next_balance,
    'receipt_id', receipt_row.id
  );
end;
$$;

revoke all on function public.grant_verified_coin_purchase(
  uuid,
  text,
  text,
  text,
  text,
  jsonb
) from public, anon, authenticated;

grant execute on function public.grant_verified_coin_purchase(
  uuid,
  text,
  text,
  text,
  text,
  jsonb
) to service_role;
