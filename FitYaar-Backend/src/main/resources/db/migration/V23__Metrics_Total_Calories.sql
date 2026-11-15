-- Some watches (Fitbit) write only total calories burned to Health Connect, not active calories.
-- Store it alongside so the workout card can still show a calorie figure.
ALTER TABLE workout_session_metrics ADD COLUMN total_calories INTEGER;
