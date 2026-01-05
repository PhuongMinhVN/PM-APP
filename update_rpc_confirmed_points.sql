-- 1. Update RPC: Get Single User Stats (Only Confirmed Orders)
create or replace function get_sales_reward_stats(user_id uuid)
returns json
language plpgsql
security definer
as $$
declare
  points_today int;
  points_month int;
  points_total int;
begin
  -- Today
  select coalesce(sum(oi.reward_points), 0)
  into points_today
  from order_items oi
  join orders o on oi.order_id = o.id
  where o.seller_id = user_id
    and o.status = 'confirmed' -- Only confirmed orders
    and date(timezone('Asia/Ho_Chi_Minh', o.created_at)) = date(timezone('Asia/Ho_Chi_Minh', now()));

  -- This Month
  select coalesce(sum(oi.reward_points), 0)
  into points_month
  from order_items oi
  join orders o on oi.order_id = o.id
  where o.seller_id = user_id
    and o.status = 'confirmed' -- Only confirmed orders
    and date_trunc('month', timezone('Asia/Ho_Chi_Minh', o.created_at)) = date_trunc('month', timezone('Asia/Ho_Chi_Minh', now()));

  -- Total
  select coalesce(sum(oi.reward_points), 0)
  into points_total
  from order_items oi
  join orders o on oi.order_id = o.id
  where o.seller_id = user_id
    and o.status = 'confirmed'; -- Only confirmed orders

  return json_build_object(
    'today', points_today,
    'month', points_month,
    'total', points_total
  );
end;
$$;


-- 2. Update RPC: Get All Users Stats (Only Confirmed Orders)
create or replace function get_all_users_points_stats()
returns table (
  user_id uuid,
  full_name text,
  points_today int,
  points_month int,
  points_total int
)
language plpgsql
security definer
as $$
begin
  return query
  select 
    p.id as user_id,
    p.full_name,
    -- Today
    coalesce((
      select sum(oi.reward_points)
      from order_items oi
      join orders o on oi.order_id = o.id
      where o.seller_id = p.id
        and o.status = 'confirmed' -- Only confirmed orders
        and date(timezone('Asia/Ho_Chi_Minh', o.created_at)) = date(timezone('Asia/Ho_Chi_Minh', now()))
    ), 0)::int as points_today,
    -- Month
    coalesce((
      select sum(oi.reward_points)
      from order_items oi
      join orders o on oi.order_id = o.id
      where o.seller_id = p.id
        and o.status = 'confirmed' -- Only confirmed orders
        and date_trunc('month', timezone('Asia/Ho_Chi_Minh', o.created_at)) = date_trunc('month', timezone('Asia/Ho_Chi_Minh', now()))
    ), 0)::int as points_month,
    -- Total
    coalesce((
      select sum(oi.reward_points)
      from order_items oi
      join orders o on oi.order_id = o.id
      where o.seller_id = p.id
        and o.status = 'confirmed' -- Only confirmed orders
    ), 0)::int as points_total
  from profiles p
  order by points_today desc, points_total desc;
end;
$$;
