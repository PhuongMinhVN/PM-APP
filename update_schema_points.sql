-- RUN THIS IN SUPABASE SQL EDITOR

-- 1. Add reward_points to order_items
ALTER TABLE public.order_items 
ADD COLUMN reward_points int DEFAULT 0;

-- 2. Create app_settings table
CREATE TABLE IF NOT EXISTS public.app_settings (
  key text PRIMARY KEY,
  value text,
  created_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read settings (for app config)
CREATE POLICY "Public read access" ON public.app_settings FOR SELECT USING (true);

-- Only Admin can update settings
CREATE POLICY "Admin update access" ON public.app_settings 
FOR ALL 
USING (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'))
WITH CHECK (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));


-- 3. RPC: Get Single User Stats
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
    and date(timezone('Asia/Ho_Chi_Minh', o.created_at)) = date(timezone('Asia/Ho_Chi_Minh', now()));

  -- This Month
  select coalesce(sum(oi.reward_points), 0)
  into points_month
  from order_items oi
  join orders o on oi.order_id = o.id
  where o.seller_id = user_id
    and date_trunc('month', timezone('Asia/Ho_Chi_Minh', o.created_at)) = date_trunc('month', timezone('Asia/Ho_Chi_Minh', now()));

  -- Total
  select coalesce(sum(oi.reward_points), 0)
  into points_total
  from order_items oi
  join orders o on oi.order_id = o.id
  where o.seller_id = user_id;

  return json_build_object(
    'today', points_today,
    'month', points_month,
    'total', points_total
  );
end;
$$;


-- 4. RPC: Get All Users Stats (For Admin)
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
        and date(timezone('Asia/Ho_Chi_Minh', o.created_at)) = date(timezone('Asia/Ho_Chi_Minh', now()))
    ), 0)::int as points_today,
    -- Month
    coalesce((
      select sum(oi.reward_points)
      from order_items oi
      join orders o on oi.order_id = o.id
      where o.seller_id = p.id
        and date_trunc('month', timezone('Asia/Ho_Chi_Minh', o.created_at)) = date_trunc('month', timezone('Asia/Ho_Chi_Minh', now()))
    ), 0)::int as points_month,
    -- Total
    coalesce((
      select sum(oi.reward_points)
      from order_items oi
      join orders o on oi.order_id = o.id
      where o.seller_id = p.id
    ), 0)::int as points_total
  from profiles p
  order by points_today desc, points_total desc;
end;
$$;
