-- Gym "live" section: track which zone a checked-in member is training in
-- (free weights / racks / cardio / machines / functional), derived client-side
-- from the active workout's equipment. Nullable — null means "open gym".
ALTER TABLE gym_checkins ADD COLUMN zone VARCHAR(32);
