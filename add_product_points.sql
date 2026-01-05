-- Add reward_points column to products table
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS reward_points int DEFAULT 0;

-- Comment on column
COMMENT ON COLUMN public.products.reward_points IS 'Points awarded when this specific product is sold. Overrides category default if > 0.';
