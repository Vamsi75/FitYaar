package com.fityaar.workout.service;

import com.fityaar.exception.ResourceNotFoundException;
import com.fityaar.user.entity.User;
import com.fityaar.workout.dto.ExerciseResponse;
import com.fityaar.workout.dto.PersonalRecordResponse;
import com.fityaar.workout.dto.WorkoutSessionRequest;
import com.fityaar.workout.dto.WorkoutSessionResponse;
import com.fityaar.workout.entity.*;
import com.fityaar.workout.event.WorkoutFinishedEvent;
import com.fityaar.workout.repository.ExerciseRepository;
import com.fityaar.workout.repository.PersonalRecordRepository;
import com.fityaar.workout.repository.RoutineRepository;
import com.fityaar.workout.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class WorkoutService {

    private final WorkoutSessionRepository sessionRepository;
    private final ExerciseRepository exerciseRepository;
    private final RoutineRepository routineRepository;
    private final PersonalRecordRepository personalRecordRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional
    public WorkoutSessionResponse startSession(User user, WorkoutSessionRequest request) {
        WorkoutSession session = WorkoutSession.builder()
                .name(request.getName() != null ? request.getName() : "Workout " + LocalDateTime.now())
                .user(user)
                .routine(request.getRoutineId() != null
                        ? routineRepository.findById(request.getRoutineId()).orElse(null)
                        : null)
                .startTime(request.getStartTime() != null ? request.getStartTime() : LocalDateTime.now())
                .endTime(request.getEndTime())
                .notes(request.getNotes())
                .build();

        List<WorkoutExercise> exercises = buildExercises(session, request);
        session.setExercises(exercises);
        session.setTotalVolume(calculateVolume(exercises));

        WorkoutSession savedSession = sessionRepository.save(session);
        updatePersonalRecords(user, savedSession);
        // Finishing a workout auto checks the user out of any gym.
        eventPublisher.publishEvent(new WorkoutFinishedEvent(user));
        return mapToResponse(savedSession);
    }

    @Transactional
    public WorkoutSessionResponse updateSession(User user, Long sessionId, WorkoutSessionRequest request) {
        WorkoutSession session = requireOwnedSession(user, sessionId);

        if (request.getName() != null) session.setName(request.getName());
        session.setNotes(request.getNotes());
        if (request.getStartTime() != null) session.setStartTime(request.getStartTime());
        session.setEndTime(request.getEndTime());

        // orphanRemoval=true on the collection deletes the previous exercises/sets.
        session.getExercises().clear();
        session.getExercises().addAll(buildExercises(session, request));
        session.setTotalVolume(calculateVolume(session.getExercises()));

        WorkoutSession saved = sessionRepository.save(session);
        updatePersonalRecords(user, saved);
        return mapToResponse(saved);
    }

    @Transactional
    public void deleteSession(User user, Long sessionId) {
        WorkoutSession session = requireOwnedSession(user, sessionId);
        // Detach any PRs pointing at this session so the FK doesn't block the delete.
        List<PersonalRecord> prs = personalRecordRepository.findByWorkoutSession(session);
        prs.forEach(pr -> pr.setWorkoutSession(null));
        personalRecordRepository.saveAll(prs);
        sessionRepository.delete(session);
    }

    public List<WorkoutSessionResponse> getUserHistory(User user) {
        return sessionRepository.findByUserOrderByStartTimeDesc(user).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    /**
     * Text search across name + muscle groups + equipment + category (so "abs" returns all ab
     * work), with optional muscle-group and equipment filters. Filtered in-memory over the small
     * exercise catalog for flexibility.
     */
    public List<ExerciseResponse> searchExercises(User user, String query, String muscle, String equipment) {
        String q = query == null ? "" : query.trim().toLowerCase();
        return exerciseRepository.findVisible(user.getId()).stream()
                .filter(e -> matchesQuery(e, q))
                .filter(e -> muscle == null || muscle.isBlank() || hasMuscle(e, muscle))
                .filter(e -> equipment == null || equipment.isBlank() || equipmentMatches(e, equipment))
                .map(this::mapExerciseToResponse)
                .collect(Collectors.toList());
    }

    private boolean matchesQuery(Exercise e, String q) {
        if (q.isEmpty()) return true;
        if (e.getName() != null && e.getName().toLowerCase().contains(q)) return true;
        if (e.getCategory() != null && enumMatches(e.getCategory().name(), q)) return true;
        if (e.getEquipment() != null && enumMatches(e.getEquipment().name(), q)) return true;
        if (e.getPrimaryMuscleGroups() != null) {
            for (var mg : e.getPrimaryMuscleGroups()) {
                if (enumMatches(mg.name(), q)) return true;
            }
        }
        if (e.getSecondaryMuscleGroups() != null) {
            for (var mg : e.getSecondaryMuscleGroups()) {
                if (enumMatches(mg.name(), q)) return true;
            }
        }
        return false;
    }

    private boolean enumMatches(String enumName, String q) {
        String lower = enumName.toLowerCase();
        return lower.contains(q) || lower.replace('_', ' ').contains(q);
    }

    private boolean hasMuscle(Exercise e, String muscle) {
        String m = muscle.toUpperCase();
        if (e.getPrimaryMuscleGroups() != null) {
            for (var mg : e.getPrimaryMuscleGroups()) {
                if (mg.name().equals(m)) return true;
            }
        }
        if (e.getSecondaryMuscleGroups() != null) {
            for (var mg : e.getSecondaryMuscleGroups()) {
                if (mg.name().equals(m)) return true;
            }
        }
        return false;
    }

    private boolean equipmentMatches(Exercise e, String equipment) {
        return e.getEquipment() != null && e.getEquipment().name().equalsIgnoreCase(equipment);
    }

    public List<PersonalRecordResponse> getUserPRs(User user) {
        return personalRecordRepository.findByUser(user).stream()
                .map(this::mapToPRResponse)
                .collect(Collectors.toList());
    }

    // ---- helpers ----

    private WorkoutSession requireOwnedSession(User user, Long sessionId) {
        WorkoutSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Workout not found: " + sessionId));
        if (session.getUser() == null || !session.getUser().getId().equals(user.getId())) {
            // Don't leak existence of other users' sessions.
            throw new ResourceNotFoundException("Workout not found: " + sessionId);
        }
        return session;
    }

    private List<WorkoutExercise> buildExercises(WorkoutSession session, WorkoutSessionRequest request) {
        return request.getExercises().stream()
                .map(exReq -> {
                    Exercise exercise = exerciseRepository.findById(exReq.getExerciseId())
                            .orElseThrow(() -> new ResourceNotFoundException(
                                    "Exercise not found: " + exReq.getExerciseId()));

                    WorkoutExercise we = WorkoutExercise.builder()
                            .workoutSession(session)
                            .exercise(exercise)
                            .orderIndex(exReq.getOrderIndex())
                            .notes(exReq.getNotes())
                            .build();

                    List<SetEntry> sets = exReq.getSets().stream()
                            .map(setReq -> SetEntry.builder()
                                    .workoutExercise(we)
                                    .orderIndex(setReq.getOrderIndex())
                                    .weight(setReq.getWeight())
                                    .reps(setReq.getReps())
                                    .rpe(setReq.getRpe())
                                    .durationSeconds(setReq.getDurationSeconds())
                                    .distanceMeters(setReq.getDistanceMeters())
                                    .type(setReq.getType())
                                    .isCompleted(setReq.getIsCompleted() != null && setReq.getIsCompleted())
                                    .build())
                            .collect(Collectors.toList());

                    we.setSets(sets);
                    return we;
                }).collect(Collectors.toList());
    }

    private void updatePersonalRecords(User user, WorkoutSession session) {
        for (WorkoutExercise we : session.getExercises()) {
            Exercise exercise = we.getExercise();
            SetEntry bestSet = we.getSets().stream()
                    .filter(SetEntry::getIsCompleted)
                    .filter(s -> s.getWeight() != null && s.getReps() != null)
                    .max((s1, s2) -> Double.compare(
                            calculateEstimated1RM(s1.getWeight(), s1.getReps()),
                            calculateEstimated1RM(s2.getWeight(), s2.getReps())))
                    .orElse(null);

            if (bestSet != null) {
                double currentORM = calculateEstimated1RM(bestSet.getWeight(), bestSet.getReps());
                PersonalRecord existingPR =
                        personalRecordRepository.findByUserAndExercise(user, exercise).orElse(null);

                if (existingPR == null || currentORM > existingPR.getOneRepMaxEstimate()) {
                    if (existingPR == null) {
                        existingPR = PersonalRecord.builder()
                                .user(user)
                                .exercise(exercise)
                                .build();
                    }
                    existingPR.setWeight(bestSet.getWeight());
                    existingPR.setReps(bestSet.getReps());
                    existingPR.setOneRepMaxEstimate(currentORM);
                    existingPR.setAchievedDate(session.getStartTime().toLocalDate());
                    existingPR.setWorkoutSession(session);
                    personalRecordRepository.save(existingPR);
                }
            }
        }
    }

    private double calculateEstimated1RM(double weight, int reps) {
        if (reps == 0) return 0;
        if (reps == 1) return weight;
        // Brzycki: 1RM = weight / (1.0278 - (0.0278 * reps))
        return weight / (1.0278 - (0.0278 * reps));
    }

    private Integer calculateVolume(List<WorkoutExercise> exercises) {
        return exercises.stream()
                .flatMap(we -> we.getSets().stream())
                .filter(SetEntry::getIsCompleted)
                .filter(s -> s.getWeight() != null && s.getReps() != null)
                .mapToInt(s -> (int) (s.getWeight() * s.getReps()))
                .sum();
    }

    private WorkoutSessionResponse mapToResponse(WorkoutSession session) {
        return WorkoutSessionResponse.builder()
                .id(session.getId())
                .name(session.getName())
                .routineId(session.getRoutine() != null ? session.getRoutine().getId() : null)
                .startTime(session.getStartTime())
                .endTime(session.getEndTime())
                .notes(session.getNotes())
                .totalVolume(session.getTotalVolume())
                .exercises(session.getExercises().stream()
                        .map(we -> WorkoutSessionResponse.WorkoutExerciseResponse.builder()
                                .id(we.getId())
                                .exerciseId(we.getExercise().getId())
                                .exerciseName(we.getExercise().getName())
                                .exerciseType(we.getExercise().getExerciseType() == null
                                        ? null
                                        : we.getExercise().getExerciseType().name())
                                .orderIndex(we.getOrderIndex())
                                .notes(we.getNotes())
                                .sets(we.getSets().stream()
                                        .map(s -> WorkoutSessionResponse.SetEntryResponse.builder()
                                                .id(s.getId())
                                                .orderIndex(s.getOrderIndex())
                                                .weight(s.getWeight())
                                                .reps(s.getReps())
                                                .rpe(s.getRpe())
                                                .durationSeconds(s.getDurationSeconds())
                                                .distanceMeters(s.getDistanceMeters())
                                                .type(s.getType())
                                                .isCompleted(s.getIsCompleted())
                                                .build())
                                        .collect(Collectors.toList()))
                                .build())
                        .collect(Collectors.toList()))
                .build();
    }

    private ExerciseResponse mapExerciseToResponse(Exercise ex) {
        return ExerciseResponse.builder()
                .id(ex.getId())
                .name(ex.getName())
                .description(ex.getDescription())
                .primaryMuscleGroups(ex.getPrimaryMuscleGroups())
                .secondaryMuscleGroups(ex.getSecondaryMuscleGroups())
                .equipment(ex.getEquipment())
                .exerciseType(ex.getExerciseType())
                .category(ex.getCategory())
                .isCustom(ex.getIsCustom())
                .build();
    }

    private PersonalRecordResponse mapToPRResponse(PersonalRecord pr) {
        return PersonalRecordResponse.builder()
                .id(pr.getId())
                .exerciseId(pr.getExercise().getId())
                .exerciseName(pr.getExercise().getName())
                .weight(pr.getWeight())
                .reps(pr.getReps())
                .oneRepMaxEstimate(pr.getOneRepMaxEstimate())
                .achievedDate(pr.getAchievedDate())
                .build();
    }
}
