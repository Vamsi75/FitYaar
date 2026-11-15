package com.fityaar.workout.importer;

import com.fityaar.user.entity.User;
import com.fityaar.workout.dto.WorkoutImportResult;
import com.fityaar.workout.entity.Exercise;
import com.fityaar.workout.entity.SetEntry;
import com.fityaar.workout.entity.WorkoutExercise;
import com.fityaar.workout.entity.WorkoutSession;
import com.fityaar.workout.importer.ParsedWorkout.ParsedExercise;
import com.fityaar.workout.importer.ParsedWorkout.ParsedSet;
import com.fityaar.workout.repository.ExerciseAliasRepository;
import com.fityaar.workout.repository.ExerciseRepository;
import com.fityaar.workout.repository.WorkoutSessionRepository;
import com.fityaar.workout.service.WorkoutService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * Imports workout history from a Hevy or Strong CSV export.
 *
 * <ul>
 *   <li>Exercises are matched to the catalog ({@link ExerciseMatcher}); names that don't match
 *       confidently become the user's own custom exercises (reused on the next import).</li>
 *   <li>A workout whose start minute already exists for the user is skipped, so re-uploading
 *       the same (or a newer, overlapping) export is safe.</li>
 *   <li>Workouts are saved oldest-first so PRs end up dated correctly.</li>
 *   <li>{@code dryRun} parses and matches without writing anything — the app shows it as a preview.</li>
 * </ul>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class WorkoutImportService {

    private static final int MAX_NAME = 255;

    private final ExerciseRepository exerciseRepository;
    private final ExerciseAliasRepository aliasRepository;
    private final WorkoutSessionRepository sessionRepository;
    private final WorkoutService workoutService;

    @Transactional
    public WorkoutImportResult importCsv(User user, String csv, WorkoutCsvParser.WeightUnit unit, boolean dryRun) {
        WorkoutCsvParser.Result parsed = WorkoutCsvParser.parse(csv, unit);
        WorkoutSession.Source source = parsed.format() == WorkoutCsvParser.Format.HEVY
                ? WorkoutSession.Source.HEVY : WorkoutSession.Source.STRONG;

        // --- resolve every distinct exercise name once ---
        ExerciseMatcher matcher = new ExerciseMatcher(
                exerciseRepository.findVisible(user.getId()), aliasRepository.findAllWithExercise());
        Map<String, Resolved> resolved = new LinkedHashMap<>();
        for (ParsedWorkout w : parsed.workouts()) {
            for (ParsedExercise pe : w.exercises()) {
                Resolved r = resolved.computeIfAbsent(pe.name(), name -> matcher.match(name)
                        .map(m -> new Resolved(m.exercise(), m.method().name()))
                        .orElseGet(() -> new Resolved(null, "NEW_CUSTOM")));
                r.sets += pe.sets().size();
                r.samples.add(pe);
            }
        }

        // --- duplicate detection (by start minute) ---
        Set<LocalDateTime> existing = new HashSet<>();
        for (LocalDateTime t : sessionRepository.startTimesForUser(user)) {
            if (t != null) existing.add(t.truncatedTo(ChronoUnit.MINUTES));
        }
        List<ParsedWorkout> toImport = new ArrayList<>();
        int duplicates = 0;
        for (ParsedWorkout w : parsed.workouts()) {
            if (existing.add(w.start().truncatedTo(ChronoUnit.MINUTES))) toImport.add(w);
            else duplicates++;
        }

        // --- write ---
        int sets = 0;
        if (!dryRun) {
            for (Map.Entry<String, Resolved> e : resolved.entrySet()) {
                if (e.getValue().exercise == null) {
                    e.getValue().exercise = createCustom(user, e.getKey(), e.getValue().samples);
                }
            }
            for (ParsedWorkout w : toImport) {
                workoutService.saveImported(user, toSession(user, w, source, resolved));
                sets += w.setCount();
            }
            log.info("User {} imported {} {} workouts ({} sets, {} duplicates skipped)",
                    user.getId(), toImport.size(), parsed.format(), sets, duplicates);
        } else {
            for (ParsedWorkout w : toImport) sets += w.setCount();
        }

        List<WorkoutImportResult.ExerciseMapping> mappings = resolved.entrySet().stream()
                .map(e -> WorkoutImportResult.ExerciseMapping.builder()
                        .sourceName(e.getKey())
                        .exerciseId(e.getValue().exercise == null ? null : e.getValue().exercise.getId())
                        .exerciseName(e.getValue().exercise == null ? e.getKey() : e.getValue().exercise.getName())
                        .method(e.getValue().method)
                        .sets(e.getValue().sets)
                        .build())
                .sorted(Comparator.comparing(WorkoutImportResult.ExerciseMapping::getSets).reversed())
                .toList();

        List<ParsedWorkout> all = parsed.workouts();
        return WorkoutImportResult.builder()
                .format(parsed.format().name())
                .dryRun(dryRun)
                .workoutsFound(all.size())
                .workoutsImported(toImport.size())
                .duplicatesSkipped(duplicates)
                .setsImported(sets)
                .rowsSkipped(parsed.rowsSkipped())
                .firstWorkout(all.isEmpty() ? null : all.get(0).start())
                .lastWorkout(all.isEmpty() ? null : all.get(all.size() - 1).start())
                .exercises(mappings)
                .warnings(parsed.warnings())
                .build();
    }

    // ---- helpers ----

    private static final class Resolved {
        Exercise exercise;
        final String method;
        int sets;
        final List<ParsedExercise> samples = new ArrayList<>();

        Resolved(Exercise exercise, String method) {
            this.exercise = exercise;
            this.method = method;
        }
    }

    private WorkoutSession toSession(User user, ParsedWorkout w, WorkoutSession.Source source,
                                     Map<String, Resolved> resolved) {
        WorkoutSession session = WorkoutSession.builder()
                .name(truncate(w.title()))
                .user(user)
                .startTime(w.start())
                .endTime(w.end())
                .notes(w.notes())
                .source(source)
                .build();
        List<WorkoutExercise> exercises = new ArrayList<>();
        int order = 0;
        for (ParsedExercise pe : w.exercises()) {
            WorkoutExercise we = WorkoutExercise.builder()
                    .workoutSession(session)
                    .exercise(resolved.get(pe.name()).exercise)
                    .orderIndex(order++)
                    .notes(pe.notes())
                    .build();
            List<SetEntry> sets = new ArrayList<>();
            int setOrder = 0;
            for (ParsedSet ps : pe.sets()) {
                sets.add(SetEntry.builder()
                        .workoutExercise(we)
                        .orderIndex(setOrder++)
                        .weight(ps.weightKg())
                        .reps(ps.reps())
                        .rpe(ps.rpe())
                        .durationSeconds(ps.durationSeconds())
                        .distanceMeters(ps.distanceMeters())
                        .type(ps.type())
                        .isCompleted(true) // other apps only export sets that were logged
                        .build());
            }
            we.setSets(sets);
            exercises.add(we);
        }
        session.setExercises(exercises);
        return session;
    }

    /** Custom exercise typed from the data seen for it (distance → cardio, time-only → duration…). */
    private Exercise createCustom(User user, String name, List<ParsedExercise> samples) {
        boolean distance = false, duration = false, reps = false, weight = false;
        for (ParsedExercise pe : samples) {
            for (ParsedSet s : pe.sets()) {
                distance |= s.distanceMeters() != null && s.distanceMeters() > 0;
                duration |= s.durationSeconds() != null && s.durationSeconds() > 0;
                reps |= s.reps() != null && s.reps() > 0;
                weight |= s.weightKg() != null && s.weightKg() > 0;
            }
        }
        Exercise.ExerciseType type;
        Exercise.Category category;
        if (distance) {
            type = Exercise.ExerciseType.DISTANCE_DURATION;
            category = Exercise.Category.CARDIO;
        } else if (duration && !reps) {
            type = weight ? Exercise.ExerciseType.DURATION_WEIGHT : Exercise.ExerciseType.DURATION;
            category = Exercise.Category.STRENGTH;
        } else if (weight) {
            type = Exercise.ExerciseType.WEIGHT_REPS;
            category = Exercise.Category.STRENGTH;
        } else {
            type = Exercise.ExerciseType.BODYWEIGHT_REPS;
            category = Exercise.Category.BODYWEIGHT;
        }
        Exercise.Equipment equipment = ExerciseMatcher.equipmentOf(name);
        Exercise custom = Exercise.builder()
                .name(truncate(name))
                .isCustom(true)
                .createdByUserId(user.getId())
                .equipment(equipment != null ? equipment
                        : (type == Exercise.ExerciseType.BODYWEIGHT_REPS ? Exercise.Equipment.NO_EQUIPMENT
                        : Exercise.Equipment.OTHER))
                .exerciseType(type)
                .category(category)
                .primaryMuscleGroups(new HashSet<>())
                .secondaryMuscleGroups(new HashSet<>())
                .build();
        return exerciseRepository.save(custom);
    }

    private static String truncate(String s) {
        return s == null || s.length() <= MAX_NAME ? s : s.substring(0, MAX_NAME);
    }
}
