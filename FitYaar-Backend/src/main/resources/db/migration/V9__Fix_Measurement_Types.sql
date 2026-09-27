-- Hibernate maps Double -> double precision (float8); align the columns so
-- ddl-auto: validate passes.
ALTER TABLE body_measurements
    ALTER COLUMN weight_kg TYPE double precision,
    ALTER COLUMN waist_cm TYPE double precision,
    ALTER COLUMN body_fat_pct TYPE double precision;
