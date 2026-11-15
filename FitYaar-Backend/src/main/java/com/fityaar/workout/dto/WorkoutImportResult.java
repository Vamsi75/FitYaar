package com.fityaar.workout.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/** Outcome (or, for a dry run, preview) of importing a Hevy / Strong CSV export. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutImportResult {
    /** HEVY or STRONG — detected from the CSV header. */
    private String format;
    private boolean dryRun;

    private int workoutsFound;
    private int workoutsImported;
    /** Workouts already in FitYaar (same start minute) — never imported twice. */
    private int duplicatesSkipped;
    private int setsImported;
    /** Rows that couldn't be read (bad date / number) or held no set data. */
    private int rowsSkipped;

    private LocalDateTime firstWorkout;
    private LocalDateTime lastWorkout;

    /** How each distinct exercise name in the file was resolved. */
    private List<ExerciseMapping> exercises;
    private List<String> warnings;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExerciseMapping {
        private String sourceName;
        private Long exerciseId;
        private String exerciseName;
        /** ALIAS | EXACT | FUZZY (catalog match) · NEW_CUSTOM (a custom exercise is/was created). */
        private String method;
        private int sets;
    }
}
