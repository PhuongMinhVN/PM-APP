-- Add priority column to products table, default is 0. Higher value means higher priority.
ALTER TABLE products ADD COLUMN priority integer DEFAULT 0;
