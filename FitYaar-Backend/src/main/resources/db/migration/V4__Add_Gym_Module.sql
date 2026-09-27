CREATE TABLE gyms (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    join_code VARCHAR(64) NOT NULL UNIQUE,
    owner_code VARCHAR(64) NOT NULL,
    capacity INTEGER,
    banner_text TEXT,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE gym_memberships (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    gym_id BIGINT NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
    role VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    UNIQUE (user_id, gym_id)
);

CREATE TABLE gym_checkins (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    gym_id BIGINT NOT NULL REFERENCES gyms(id) ON DELETE CASCADE,
    check_in_at TIMESTAMP NOT NULL,
    check_out_at TIMESTAMP
);

-- Demo gym for testing: members join with IRON123, owners claim admin with OWNER123.
INSERT INTO gyms (name, join_code, owner_code, capacity, banner_text, created_at, updated_at)
VALUES ('Iron Temple Gym', 'IRON123', 'OWNER123', 120,
        'Welcome to Iron Temple! New squat racks just installed.', NOW(), NOW());
