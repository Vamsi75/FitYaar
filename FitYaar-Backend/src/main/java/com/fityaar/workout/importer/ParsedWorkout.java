package com.fityaar.workout.importer;

import com.fityaar.workout.entity.SetEntry;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/** A workout read from another app's CSV export, before exercises are matched to the catalog. */
public final class ParsedWorkout {

    final String title;
    final LocalDateTime start;
    LocalDateTime end;
    String notes;
    final List<ParsedExercise> exercises = new ArrayList<>();

    ParsedWorkout(String title, LocalDateTime start) {
        this.title = title;
        this.start = start;
    }

    public String title() { return title; }
    public LocalDateTime start() { return start; }
    public LocalDateTime end() { return end; }
    public String notes() { return notes; }
    public List<ParsedExercise> exercises() { return exercises; }

    public int setCount() {
        return exercises.stream().mapToInt(e -> e.sets.size()).sum();
    }

    public static final class ParsedExercise {
        final String name;
        String notes;
        final List<ParsedSet> sets = new ArrayList<>();

        ParsedExercise(String name) {
            this.name = name;
        }

        public String name() { return name; }
        public String notes() { return notes; }
        public List<ParsedSet> sets() { return sets; }
    }

    /** One set, already converted to FitYaar units (kg, metres, seconds). */
    public record ParsedSet(
            SetEntry.SetType type,
            Double weightKg,
            Integer reps,
            Integer rpe,
            Integer durationSeconds,
            Double distanceMeters) {

        boolean isEmpty() {
            return weightKg == null && reps == null && durationSeconds == null && distanceMeters == null;
        }
    }
}
