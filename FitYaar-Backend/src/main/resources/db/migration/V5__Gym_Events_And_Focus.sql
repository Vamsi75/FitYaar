-- What a member is training this session (for the live "who's doing what" breakdown).
ALTER TABLE gym_checkins ADD COLUMN focus VARCHAR(64);

-- Gym announcements / events created by admins.
CREATE TABLE gym_events (
    id BIGSERIAL PRIMARY KEY,
    gym_id BIGINT NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    starts_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
