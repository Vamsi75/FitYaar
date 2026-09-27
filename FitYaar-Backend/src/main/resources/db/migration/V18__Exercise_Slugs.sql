-- Phase B (website): the public SEO exercise library needs stable, human-readable
-- slugs (e.g. /exercises/bench-press-barbell). Backfill the shared catalog
-- (non-custom) exercises. Custom user-created exercises keep a NULL slug — they are
-- private and excluded from the public library, and NULLs never collide.

ALTER TABLE exercises ADD COLUMN slug VARCHAR(255);

-- Slugify: lowercase, non-alphanumeric runs → '-', trim leading/trailing '-'.
UPDATE exercises
SET slug = trim(BOTH '-' FROM regexp_replace(lower(name), '[^a-z0-9]+', '-', 'g'))
WHERE is_custom = FALSE OR is_custom IS NULL;

-- Disambiguate any colliding slugs by appending the row id (guarantees uniqueness).
UPDATE exercises e
SET slug = e.slug || '-' || e.id
WHERE e.slug IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM exercises other
    WHERE other.slug = e.slug AND other.id <> e.id
  );

-- Partial unique index: enforce uniqueness only over present slugs.
CREATE UNIQUE INDEX ux_exercises_slug ON exercises (slug) WHERE slug IS NOT NULL;
