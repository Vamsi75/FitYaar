-- FitYaar Pro: personal subscriptions + gym seat-tier billing.

-- Personal Pro subscriptions. A user may accumulate rows over time; "active" =
-- status ACTIVE AND (current_period_end IS NULL OR current_period_end > now()).
-- current_period_end is NULL for LIFETIME (never expires).
CREATE TABLE subscriptions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source VARCHAR(16) NOT NULL,          -- RAZORPAY | MANUAL | PROMO
    plan VARCHAR(16) NOT NULL,            -- MONTHLY | YEARLY | LIFETIME
    status VARCHAR(16) NOT NULL,          -- ACTIVE | CANCELLED | EXPIRED
    current_period_end TIMESTAMP,         -- NULL for LIFETIME (never expires)
    provider_ref VARCHAR(128),            -- payment-provider order/subscription id; NULL for MANUAL/PROMO
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_user_status ON subscriptions(user_id, status);

-- Gym B2B seat-tier billing (super-admin-driven, paid offline). One current plan per gym.
-- Active gym plan → all ACTIVE members inherit Pro (see EntitlementService).
ALTER TABLE gyms ADD COLUMN plan_tier VARCHAR(24);               -- e.g. STARTER | GROWTH | PRO_UNLIMITED (nullable = no plan)
ALTER TABLE gyms ADD COLUMN plan_status VARCHAR(16);            -- ACTIVE | SUSPENDED | EXPIRED (nullable = never set)
ALTER TABLE gyms ADD COLUMN plan_current_period_end TIMESTAMP;  -- when the gym plan lapses (NULL = no expiry)
ALTER TABLE gyms ADD COLUMN paid_seats INTEGER;                -- seats bought at this tier (advisory)
