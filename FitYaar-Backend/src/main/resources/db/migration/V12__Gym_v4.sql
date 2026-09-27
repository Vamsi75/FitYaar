-- Member contact + personal-training fields.
ALTER TABLE profiles ADD COLUMN phone VARCHAR(32);

ALTER TABLE gym_memberships ADD COLUMN expires_at DATE;
ALTER TABLE gym_memberships ADD COLUMN trainer_id BIGINT REFERENCES users(id);
ALTER TABLE gym_memberships ADD COLUMN pt_notes TEXT;

-- Structured plan items (a plan the client sees as a read-only checklist).
CREATE TABLE gym_plan_items (
    id BIGSERIAL PRIMARY KEY,
    plan_id BIGINT NOT NULL REFERENCES gym_plans(id) ON DELETE CASCADE,
    order_index INTEGER NOT NULL,
    exercise_name VARCHAR(160) NOT NULL,
    sets INTEGER,
    reps INTEGER,
    note VARCHAR(255)
);
CREATE INDEX idx_gym_plan_items_plan ON gym_plan_items (plan_id);
