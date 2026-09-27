-- Sets can now be logged by time and/or distance (not just weight × reps),
-- to support DURATION / DISTANCE_DURATION / WEIGHT_DISTANCE etc. exercise types.
ALTER TABLE set_entries ADD COLUMN duration_seconds INTEGER;
ALTER TABLE set_entries ADD COLUMN distance_meters DOUBLE PRECISION;
