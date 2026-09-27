-- Personal + social fields for the profile panel.
-- gender and birthday are private (not shown on public profiles).
ALTER TABLE profiles ADD COLUMN gender VARCHAR(50);
ALTER TABLE profiles ADD COLUMN birthday DATE;
ALTER TABLE profiles ADD COLUMN instagram VARCHAR(255);
ALTER TABLE profiles ADD COLUMN website VARCHAR(255);
