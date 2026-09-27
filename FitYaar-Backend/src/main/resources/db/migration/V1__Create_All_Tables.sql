-- V1: Baseline schema. Runs once on an empty database (Flyway-managed).
-- NOTE: intentionally no DROP statements — a baseline must never destroy an existing database.

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    google_id VARCHAR(255),
    role VARCHAR(50),
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id),
    display_name VARCHAR(255),
    profile_picture_url VARCHAR(255),
    bio TEXT,
    fitness_goal VARCHAR(255),
    current_weight DOUBLE PRECISION,
    target_weight DOUBLE PRECISION,
    height DOUBLE PRECISION,
    waist DOUBLE PRECISION,
    body_fat_percentage DOUBLE PRECISION,
    daily_calorie_goal DOUBLE PRECISION,
    daily_water_goal DOUBLE PRECISION,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE water_entries (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    date DATE NOT NULL,
    amount_ml INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE food_items (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(255),
    serving_size DOUBLE PRECISION,
    serving_unit VARCHAR(255),
    portion_name VARCHAR(255),
    calories DOUBLE PRECISION,
    protein DOUBLE PRECISION,
    carbs DOUBLE PRECISION,
    fat DOUBLE PRECISION,
    fiber DOUBLE PRECISION,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE nutrition_entries (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    food_item_id BIGINT NOT NULL REFERENCES food_items(id),
    date DATE,
    meal_type VARCHAR(255),
    quantity DOUBLE PRECISION,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE exercises (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    equipment VARCHAR(255),
    exercise_type VARCHAR(255),
    category VARCHAR(255),
    is_custom BOOLEAN DEFAULT FALSE,
    created_by_user_id BIGINT,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE exercise_primary_muscle_groups (
    exercise_id BIGINT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    muscle_group VARCHAR(255) NOT NULL
);

CREATE TABLE exercise_secondary_muscle_groups (
    exercise_id BIGINT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    muscle_group VARCHAR(255) NOT NULL
);

CREATE TABLE routines (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    notes TEXT,
    user_id BIGINT NOT NULL REFERENCES users(id),
    is_template BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE routine_exercises (
    id BIGSERIAL PRIMARY KEY,
    routine_id BIGINT NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
    exercise_id BIGINT NOT NULL REFERENCES exercises(id),
    order_index INTEGER,
    notes TEXT
);

CREATE TABLE workout_sessions (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    user_id BIGINT NOT NULL REFERENCES users(id),
    routine_id BIGINT REFERENCES routines(id),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    notes TEXT,
    total_volume INTEGER,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE workout_exercises (
    id BIGSERIAL PRIMARY KEY,
    workout_session_id BIGINT NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
    exercise_id BIGINT NOT NULL REFERENCES exercises(id),
    order_index INTEGER,
    notes TEXT
);

CREATE TABLE set_entries (
    id BIGSERIAL PRIMARY KEY,
    workout_exercise_id BIGINT NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE,
    order_index INTEGER,
    weight DOUBLE PRECISION,
    reps INTEGER,
    rpe INTEGER,
    type VARCHAR(255),
    is_completed BOOLEAN DEFAULT FALSE
);

CREATE TABLE personal_records (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    exercise_id BIGINT NOT NULL REFERENCES exercises(id),
    weight DOUBLE PRECISION,
    reps INTEGER,
    one_rep_max_estimate DOUBLE PRECISION,
    achieved_date DATE,
    workout_session_id BIGINT REFERENCES workout_sessions(id),
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    UNIQUE(user_id, exercise_id)
);

CREATE TABLE friend_requests (
    id BIGSERIAL PRIMARY KEY,
    sender_id BIGINT NOT NULL REFERENCES users(id),
    receiver_id BIGINT NOT NULL REFERENCES users(id),
    status VARCHAR(255),
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE friendships (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    friend_id BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    UNIQUE(user_id, friend_id)
);
