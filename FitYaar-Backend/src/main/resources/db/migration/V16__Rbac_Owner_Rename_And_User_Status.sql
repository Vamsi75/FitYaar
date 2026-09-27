-- Gym role rename ADMIN -> OWNER (owner is a distinct gym role; platform super-admin stays User.role=ADMIN).
UPDATE gym_memberships SET role = 'OWNER' WHERE role = 'ADMIN';

-- User account lifecycle. Existing rows default to ACTIVE.
ALTER TABLE users ADD COLUMN status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE';
