-- Google sign-up gives users a random password they never see. Track whether the user has
-- chosen a password, so the app can offer "Set a password" instead of "Change password".
ALTER TABLE users ADD COLUMN password_set BOOLEAN NOT NULL DEFAULT TRUE;
