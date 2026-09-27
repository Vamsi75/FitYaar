-- Personal-trainer plans target one client (not the whole gym).
ALTER TABLE gym_plans ADD COLUMN client_id BIGINT REFERENCES users(id) ON DELETE CASCADE;

-- Gym classes a trainer runs on a schedule.
CREATE TABLE gym_classes (
    id BIGSERIAL PRIMARY KEY,
    gym_id BIGINT NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
    trainer_id BIGINT NOT NULL REFERENCES users(id),
    title VARCHAR(160) NOT NULL,
    schedule VARCHAR(120),
    description TEXT,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
CREATE INDEX idx_gym_classes_gym ON gym_classes (gym_id);

-- Per-user privacy: whether the member appears in the gym's active-now / leaderboard.
ALTER TABLE profiles ADD COLUMN gym_visible BOOLEAN NOT NULL DEFAULT true;
