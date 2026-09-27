CREATE TABLE body_measurements (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    measured_on DATE NOT NULL,
    weight_kg NUMERIC(6, 2),
    waist_cm NUMERIC(6, 2),
    body_fat_pct NUMERIC(5, 2),
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    UNIQUE (user_id, measured_on)
);
