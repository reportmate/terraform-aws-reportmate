-- Add missing columns to devices table
ALTER TABLE devices ADD COLUMN IF NOT EXISTS machine_group_id VARCHAR(255);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS business_unit_id VARCHAR(255);
