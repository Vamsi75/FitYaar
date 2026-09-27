-- Helper to insert exercise and its muscle groups
-- Note: In pure SQL without procedures, we have to do it step by step.
-- Since this is for initial population, we can use IDs if we are sure of the sequence or use subqueries.

-- 1. Bench Press
INSERT INTO exercises (name, description, equipment, exercise_type, category, created_at, updated_at)
VALUES ('Bench Press (Barbell)', 'Classic chest exercise', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'CHEST' FROM exercises WHERE name = 'Bench Press (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Bench Press (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Bench Press (Barbell)';

-- 2. Squat
INSERT INTO exercises (name, description, equipment, exercise_type, category, created_at, updated_at)
VALUES ('Squat (Barbell)', 'Fundamental lower body exercise', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Squat (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'GLUTES' FROM exercises WHERE name = 'Squat (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'HAMSTRINGS' FROM exercises WHERE name = 'Squat (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'LOWER_BACK' FROM exercises WHERE name = 'Squat (Barbell)';

-- 3. Deadlift
INSERT INTO exercises (name, description, equipment, exercise_type, category, created_at, updated_at)
VALUES ('Deadlift (Barbell)', 'Full body power exercise', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'Deadlift (Barbell)';
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'HAMSTRINGS' FROM exercises WHERE name = 'Deadlift (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'GLUTES' FROM exercises WHERE name = 'Deadlift (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Deadlift (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'FOREARMS' FROM exercises WHERE name = 'Deadlift (Barbell)';

-- 4. Pull Ups
INSERT INTO exercises (name, description, equipment, exercise_type, category, created_at, updated_at)
VALUES ('Pull Up', 'Bodyweight upper body pull', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'Pull Up';
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'LATS' FROM exercises WHERE name = 'Pull Up';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'BICEPS' FROM exercises WHERE name = 'Pull Up';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Pull Up';

-- 5. Dumbbell Shoulder Press
INSERT INTO exercises (name, description, equipment, exercise_type, category, created_at, updated_at)
VALUES ('Shoulder Press (Dumbbell)', 'Overhead press for shoulders', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Shoulder Press (Dumbbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Shoulder Press (Dumbbell)';

-- 6. Plank
INSERT INTO exercises (name, description, equipment, exercise_type, category, created_at, updated_at)
VALUES ('Plank', 'Core stability exercise', 'NO_EQUIPMENT', 'DURATION', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'ABS' FROM exercises WHERE name = 'Plank';

-- 7. Leg Press
INSERT INTO exercises (name, description, equipment, exercise_type, category, created_at, updated_at)
VALUES ('Leg Press (Machine)', 'Machine leg exercise', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Leg Press (Machine)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'GLUTES' FROM exercises WHERE name = 'Leg Press (Machine)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'HAMSTRINGS' FROM exercises WHERE name = 'Leg Press (Machine)';

-- 8. Bicep Curl (Dumbbell)
INSERT INTO exercises (name, description, equipment, exercise_type, category, created_at, updated_at)
VALUES ('Bicep Curl (Dumbbell)', 'Isolation exercise for biceps', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'BICEPS' FROM exercises WHERE name = 'Bicep Curl (Dumbbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'FOREARMS' FROM exercises WHERE name = 'Bicep Curl (Dumbbell)';

-- 9. Running
INSERT INTO exercises (name, description, equipment, exercise_type, category, created_at, updated_at)
VALUES ('Running', 'Cardiovascular exercise', 'NO_EQUIPMENT', 'DISTANCE_DURATION', 'CARDIO', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Running';
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'CALVES' FROM exercises WHERE name = 'Running';

-- 10. Triceps Dip (Assisted)
INSERT INTO exercises (name, description, equipment, exercise_type, category, created_at, updated_at)
VALUES ('Triceps Dip (Band Assisted)', 'Assisted dip for triceps', 'BAND', 'ASSISTED_BODYWEIGHT_REPS', 'ASSISTED_BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Triceps Dip (Band Assisted)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'CHEST' FROM exercises WHERE name = 'Triceps Dip (Band Assisted)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group)
SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Triceps Dip (Band Assisted)';
-- Helper to insert exercise and its muscle groups
-- V7 Populate More Workouts from the comprehensive list

-- CHEST
-- Barbell
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Incline Bench Press (Barbell)', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_CHEST' FROM exercises WHERE name = 'Incline Bench Press (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Incline Bench Press (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Incline Bench Press (Barbell)';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Decline Bench Press (Barbell)', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LOWER_CHEST' FROM exercises WHERE name = 'Decline Bench Press (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Decline Bench Press (Barbell)';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Close Grip Bench Press (Barbell)', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Close Grip Bench Press (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Close Grip Bench Press (Barbell)';

-- Dumbbell
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Dumbbell Bench Press', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Dumbbell Bench Press';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Incline Dumbbell Press', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_CHEST' FROM exercises WHERE name = 'Incline Dumbbell Press';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Decline Dumbbell Press', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LOWER_CHEST' FROM exercises WHERE name = 'Decline Dumbbell Press';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Dumbbell Fly', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Dumbbell Fly';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Incline Dumbbell Fly', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_CHEST' FROM exercises WHERE name = 'Incline Dumbbell Fly';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Dumbbell Pullover', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Dumbbell Pullover';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LATS' FROM exercises WHERE name = 'Dumbbell Pullover';

-- Machine
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Chest Press Machine', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Chest Press Machine';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Incline Chest Press Machine', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_CHEST' FROM exercises WHERE name = 'Incline Chest Press Machine';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Pec Deck Fly', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Pec Deck Fly';

-- Cable
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Cable Fly', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Cable Fly';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Low to High Cable Fly', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_CHEST' FROM exercises WHERE name = 'Low to High Cable Fly';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('High to Low Cable Fly', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LOWER_CHEST' FROM exercises WHERE name = 'High to Low Cable Fly';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Single Arm Cable Fly', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Single Arm Cable Fly';

-- Bodyweight
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Push Up', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Push Up';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Incline Push Up', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LOWER_CHEST' FROM exercises WHERE name = 'Incline Push Up';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Decline Push Up', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_CHEST' FROM exercises WHERE name = 'Decline Push Up';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Diamond Push Up', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Diamond Push Up';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Diamond Push Up';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Archer Push Up', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Archer Push Up';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Weighted Push Up', 'PLATE', 'WEIGHTED_BODYWEIGHT_REPS', 'WEIGHTED_BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Weighted Push Up';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Chest Dip', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LOWER_CHEST' FROM exercises WHERE name = 'Chest Dip';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Chest Dip';

-- SHOULDERS
-- Front Delts
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Dumbbell Front Raise', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Dumbbell Front Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Barbell Front Raise', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Barbell Front Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Cable Front Raise', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Cable Front Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Plate Front Raise', 'PLATE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Plate Front Raise';

-- Side Delts
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Dumbbell Lateral Raise', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'SIDE_DELTS' FROM exercises WHERE name = 'Dumbbell Lateral Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Cable Lateral Raise', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'SIDE_DELTS' FROM exercises WHERE name = 'Cable Lateral Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Machine Lateral Raise', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'SIDE_DELTS' FROM exercises WHERE name = 'Machine Lateral Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Leaning Lateral Raise', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'SIDE_DELTS' FROM exercises WHERE name = 'Leaning Lateral Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Behind Back Cable Lateral Raise', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'SIDE_DELTS' FROM exercises WHERE name = 'Behind Back Cable Lateral Raise';

-- Rear Delts
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Reverse Pec Deck', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'REAR_DELTS' FROM exercises WHERE name = 'Reverse Pec Deck';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Rear Delt Fly', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'REAR_DELTS' FROM exercises WHERE name = 'Rear Delt Fly';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Cable Rear Delt Fly', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'REAR_DELTS' FROM exercises WHERE name = 'Cable Rear Delt Fly';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Face Pull', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'REAR_DELTS' FROM exercises WHERE name = 'Face Pull';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRAPS' FROM exercises WHERE name = 'Face Pull';

-- Compound
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Overhead Press (Barbell)', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Overhead Press (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Overhead Press (Barbell)';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Seated Dumbbell Press', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Seated Dumbbell Press';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Arnold Press', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Arnold Press';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'SIDE_DELTS' FROM exercises WHERE name = 'Arnold Press';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Machine Shoulder Press', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Machine Shoulder Press';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Push Press', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Push Press';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Bradford Press', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Bradford Press';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'SIDE_DELTS' FROM exercises WHERE name = 'Bradford Press';

-- BACK
-- Lats
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Chin Up', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LATS' FROM exercises WHERE name = 'Chin Up';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Chin Up';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Neutral Grip Pull Up', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LATS' FROM exercises WHERE name = 'Neutral Grip Pull Up';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Lat Pulldown', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LATS' FROM exercises WHERE name = 'Lat Pulldown';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Wide Grip Lat Pulldown', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LATS' FROM exercises WHERE name = 'Wide Grip Lat Pulldown';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Close Grip Lat Pulldown', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LATS' FROM exercises WHERE name = 'Close Grip Lat Pulldown';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Single Arm Lat Pulldown', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LATS' FROM exercises WHERE name = 'Single Arm Lat Pulldown';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Straight Arm Pulldown', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LATS' FROM exercises WHERE name = 'Straight Arm Pulldown';

-- Rows
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Barbell Row', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'Barbell Row';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LATS' FROM exercises WHERE name = 'Barbell Row';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Pendlay Row', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'Pendlay Row';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('T-Bar Row', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'T-Bar Row';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Dumbbell Row', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LATS' FROM exercises WHERE name = 'Dumbbell Row';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Chest Supported Row', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'Chest Supported Row';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Seated Cable Row', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'Seated Cable Row';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Machine Row', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'Machine Row';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Meadows Row', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'Meadows Row';

-- Upper Back
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Reverse Fly', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'REAR_DELTS' FROM exercises WHERE name = 'Reverse Fly';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'Reverse Fly';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('High Row', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'High Row';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Rear Delt Row', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'REAR_DELTS' FROM exercises WHERE name = 'Rear Delt Row';

-- Lower Back
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Back Extension', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LOWER_BACK' FROM exercises WHERE name = 'Back Extension';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Hyperextension', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LOWER_BACK' FROM exercises WHERE name = 'Hyperextension';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Good Morning (Barbell)', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'HAMSTRINGS' FROM exercises WHERE name = 'Good Morning (Barbell)';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LOWER_BACK' FROM exercises WHERE name = 'Good Morning (Barbell)';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Superman', 'NO_EQUIPMENT', 'DURATION', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LOWER_BACK' FROM exercises WHERE name = 'Superman';

-- TRAPS
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Barbell Shrug', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRAPS' FROM exercises WHERE name = 'Barbell Shrug';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Dumbbell Shrug', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRAPS' FROM exercises WHERE name = 'Dumbbell Shrug';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Smith Machine Shrug', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRAPS' FROM exercises WHERE name = 'Smith Machine Shrug';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Behind Back Shrug', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRAPS' FROM exercises WHERE name = 'Behind Back Shrug';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Upright Row', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'SIDE_DELTS' FROM exercises WHERE name = 'Upright Row';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRAPS' FROM exercises WHERE name = 'Upright Row';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Farmer Carry', 'DUMBBELL', 'DISTANCE_DURATION', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FOREARMS' FROM exercises WHERE name = 'Farmer Carry';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRAPS' FROM exercises WHERE name = 'Farmer Carry';

-- BICEPS
-- Barbell
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Barbell Curl', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Barbell Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('EZ Bar Curl', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'EZ Bar Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Drag Curl', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Drag Curl';

-- Dumbbell
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Alternating Curl', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Alternating Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Hammer Curl', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Hammer Curl';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FOREARMS' FROM exercises WHERE name = 'Hammer Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Incline Curl', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Incline Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Concentration Curl', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Concentration Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Spider Curl', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Spider Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Zottman Curl', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Zottman Curl';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FOREARMS' FROM exercises WHERE name = 'Zottman Curl';

-- Cable
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Cable Curl', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Cable Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Rope Curl', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Rope Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Bayesian Curl', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Bayesian Curl';

-- Machine
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Preacher Curl Machine', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Preacher Curl Machine';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Cable Preacher Curl', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Cable Preacher Curl';

-- TRICEPS
-- Cable
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Rope Pushdown', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Rope Pushdown';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Straight Bar Pushdown', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Straight Bar Pushdown';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Reverse Grip Pushdown', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Reverse Grip Pushdown';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Overhead Rope Extension', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Overhead Rope Extension';

-- Dumbbell
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Overhead Extension (Dumbbell)', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Overhead Extension (Dumbbell)';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Skull Crusher', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Skull Crusher';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Kickback', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Kickback';

-- Barbell
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('JM Press', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'JM Press';

-- Bodyweight
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Bench Dip', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Bench Dip';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Parallel Bar Dip', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Parallel Bar Dip';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CHEST' FROM exercises WHERE name = 'Parallel Bar Dip';

-- Machine
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Tricep Extension Machine', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'TRICEPS' FROM exercises WHERE name = 'Tricep Extension Machine';

-- FOREARMS
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Wrist Curl', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FOREARMS' FROM exercises WHERE name = 'Wrist Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Reverse Wrist Curl', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FOREARMS' FROM exercises WHERE name = 'Reverse Wrist Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Plate Pinch Hold', 'PLATE', 'DURATION', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FOREARMS' FROM exercises WHERE name = 'Plate Pinch Hold';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Wrist Roller', 'OTHER', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FOREARMS' FROM exercises WHERE name = 'Wrist Roller';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Reverse Curl', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'BICEPS' FROM exercises WHERE name = 'Reverse Curl';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FOREARMS' FROM exercises WHERE name = 'Reverse Curl';

-- ABS
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Crunch', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Crunch';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Decline Crunch', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Decline Crunch';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Cable Crunch', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Cable Crunch';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Machine Crunch', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Machine Crunch';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Reverse Crunch', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Reverse Crunch';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Toe Touch', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Toe Touch';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Sit Up', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Sit Up';

-- LOWER ABS
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Leg Raise', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Leg Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Hanging Leg Raise', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Hanging Leg Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Lying Leg Raise', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Lying Leg Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Garhammer Raise', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Garhammer Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Dragon Flag', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Dragon Flag';

-- OBLIQUES
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Russian Twist', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'OBLIQUES' FROM exercises WHERE name = 'Russian Twist';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Cable Woodchopper', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'OBLIQUES' FROM exercises WHERE name = 'Cable Woodchopper';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Side Plank', 'NO_EQUIPMENT', 'DURATION', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'OBLIQUES' FROM exercises WHERE name = 'Side Plank';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Dumbbell Side Bend', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'OBLIQUES' FROM exercises WHERE name = 'Dumbbell Side Bend';

-- QUADS
-- Squats
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Back Squat', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Back Squat';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Front Squat', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Front Squat';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Goblet Squat', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Goblet Squat';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Hack Squat', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Hack Squat';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Smith Squat', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Smith Squat';

-- Machine
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Leg Extension', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Leg Extension';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Pendulum Squat', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Pendulum Squat';

-- Single Leg
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Bulgarian Split Squat', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Bulgarian Split Squat';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'GLUTES' FROM exercises WHERE name = 'Bulgarian Split Squat';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Walking Lunge', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Walking Lunge';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Reverse Lunge', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Reverse Lunge';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Step Up', 'DUMBBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Step Up';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'GLUTES' FROM exercises WHERE name = 'Step Up';

-- HAMSTRINGS
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Romanian Deadlift', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'HAMSTRINGS' FROM exercises WHERE name = 'Romanian Deadlift';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'GLUTES' FROM exercises WHERE name = 'Romanian Deadlift';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Stiff Leg Deadlift', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'HAMSTRINGS' FROM exercises WHERE name = 'Stiff Leg Deadlift';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Seated Leg Curl', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'HAMSTRINGS' FROM exercises WHERE name = 'Seated Leg Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Lying Leg Curl', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'HAMSTRINGS' FROM exercises WHERE name = 'Lying Leg Curl';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Nordic Curl', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'HAMSTRINGS' FROM exercises WHERE name = 'Nordic Curl';

-- GLUTES
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Hip Thrust', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'GLUTES' FROM exercises WHERE name = 'Hip Thrust';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Glute Bridge', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'GLUTES' FROM exercises WHERE name = 'Glute Bridge';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Cable Kickback', 'CABLE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'GLUTES' FROM exercises WHERE name = 'Cable Kickback';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Sumo Deadlift', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'GLUTES' FROM exercises WHERE name = 'Sumo Deadlift';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'HAMSTRINGS' FROM exercises WHERE name = 'Sumo Deadlift';

-- CALVES
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Standing Calf Raise', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CALVES' FROM exercises WHERE name = 'Standing Calf Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Seated Calf Raise', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CALVES' FROM exercises WHERE name = 'Seated Calf Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Leg Press Calf Raise', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CALVES' FROM exercises WHERE name = 'Leg Press Calf Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Single Leg Calf Raise', 'NO_EQUIPMENT', 'BODYWEIGHT_REPS', 'BODYWEIGHT', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CALVES' FROM exercises WHERE name = 'Single Leg Calf Raise';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Donkey Calf Raise', 'MACHINE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CALVES' FROM exercises WHERE name = 'Donkey Calf Raise';

-- NECK
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Neck Flexion', 'PLATE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'NECK' FROM exercises WHERE name = 'Neck Flexion';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Neck Extension', 'PLATE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'NECK' FROM exercises WHERE name = 'Neck Extension';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Neck Lateral Flexion', 'PLATE', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'NECK' FROM exercises WHERE name = 'Neck Lateral Flexion';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Neck Harness Extension', 'OTHER', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'NECK' FROM exercises WHERE name = 'Neck Harness Extension';

-- OLYMPIC LIFTS
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Clean', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Clean';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'Clean';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Power Clean', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Power Clean';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Hang Clean', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Hang Clean';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Snatch', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Snatch';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Power Snatch', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Power Snatch';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Clean and Jerk', 'BARBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Clean and Jerk';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Clean and Jerk';

-- KETTLEBELL
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Kettlebell Swing', 'KETTLEBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'HAMSTRINGS' FROM exercises WHERE name = 'Kettlebell Swing';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'GLUTES' FROM exercises WHERE name = 'Kettlebell Swing';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Turkish Get Up', 'KETTLEBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'ABS' FROM exercises WHERE name = 'Turkish Get Up';
INSERT INTO exercise_secondary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Turkish Get Up';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Kettlebell Press', 'KETTLEBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'FRONT_DELTS' FROM exercises WHERE name = 'Kettlebell Press';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Kettlebell Row', 'KETTLEBELL', 'WEIGHT_REPS', 'STRENGTH', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LATS' FROM exercises WHERE name = 'Kettlebell Row';

-- CARDIO
INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Walking', 'NO_EQUIPMENT', 'DISTANCE_DURATION', 'CARDIO', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Walking';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Treadmill Walk', 'MACHINE', 'DISTANCE_DURATION', 'CARDIO', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Treadmill Walk';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Cycling', 'MACHINE', 'DISTANCE_DURATION', 'CARDIO', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Cycling';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Stair Climber', 'MACHINE', 'DURATION', 'CARDIO', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Stair Climber';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Rowing', 'MACHINE', 'DISTANCE_DURATION', 'CARDIO', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'UPPER_BACK' FROM exercises WHERE name = 'Rowing';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Elliptical', 'MACHINE', 'DISTANCE_DURATION', 'CARDIO', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'QUADRICEPS' FROM exercises WHERE name = 'Elliptical';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Swimming', 'NO_EQUIPMENT', 'DISTANCE_DURATION', 'CARDIO', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'LATS' FROM exercises WHERE name = 'Swimming';

INSERT INTO exercises (name, equipment, exercise_type, category, created_at, updated_at) VALUES ('Jump Rope', 'OTHER', 'DURATION', 'CARDIO', NOW(), NOW());
INSERT INTO exercise_primary_muscle_groups (exercise_id, muscle_group) SELECT id, 'CALVES' FROM exercises WHERE name = 'Jump Rope';
