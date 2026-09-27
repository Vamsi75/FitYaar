CREATE TABLE gym_plans (
    id BIGSERIAL PRIMARY KEY,
    gym_id BIGINT NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
    author_id BIGINT NOT NULL REFERENCES users(id),
    plan_date DATE NOT NULL,
    title VARCHAR(160) NOT NULL,
    body TEXT,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_gym_plans_gym ON gym_plans (gym_id, plan_date DESC);
