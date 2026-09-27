-- Add settings and preference fields to users table
ALTER TABLE users ADD COLUMN theme VARCHAR(50);
ALTER TABLE users ADD COLUMN language VARCHAR(50);
ALTER TABLE users ADD COLUMN weight_unit VARCHAR(50);
ALTER TABLE users ADD COLUMN distance_unit VARCHAR(50);
ALTER TABLE users ADD COLUMN measurement_unit VARCHAR(50);
