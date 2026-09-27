-- Human/admin action audit trail (the platform's operational black box).
-- actor_email is denormalized so a log line survives even if the user row is later removed.
CREATE TABLE audit_logs (
    id            BIGSERIAL PRIMARY KEY,
    actor_id      BIGINT,
    actor_email   VARCHAR(255),
    action        VARCHAR(64) NOT NULL,
    resource_type VARCHAR(64),
    resource_id   VARCHAR(64),
    gym_id        BIGINT,
    metadata      TEXT,
    ip            VARCHAR(64),
    created_at    TIMESTAMP NOT NULL,
    updated_at    TIMESTAMP NOT NULL
);

CREATE INDEX idx_audit_created_at ON audit_logs (created_at DESC);
CREATE INDEX idx_audit_gym        ON audit_logs (gym_id);
CREATE INDEX idx_audit_actor      ON audit_logs (actor_id);
CREATE INDEX idx_audit_action     ON audit_logs (action);
