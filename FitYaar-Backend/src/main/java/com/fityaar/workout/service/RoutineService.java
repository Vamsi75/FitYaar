package com.fityaar.workout.service;

import com.fityaar.exception.ResourceNotFoundException;
import com.fityaar.user.entity.User;
import com.fityaar.workout.dto.RoutineRequest;
import com.fityaar.workout.dto.RoutineResponse;
import com.fityaar.workout.entity.Exercise;
import com.fityaar.workout.entity.Routine;
import com.fityaar.workout.entity.RoutineExercise;
import com.fityaar.workout.repository.ExerciseRepository;
import com.fityaar.workout.repository.RoutineRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RoutineService {

    private final RoutineRepository routineRepository;
    private final ExerciseRepository exerciseRepository;

    @Transactional
    public RoutineResponse createRoutine(User user, RoutineRequest request) {
        Routine routine = Routine.builder()
                .name(request.getName())
                .notes(request.getNotes())
                .user(user)
                .isTemplate(request.getIsTemplate() != null ? request.getIsTemplate() : false)
                .build();

        List<RoutineExercise> routineExercises = request.getExercises().stream()
                .map(req -> {
                    Exercise exercise = exerciseRepository.findById(req.getExerciseId())
                            .orElseThrow(() -> new RuntimeException("Exercise not found: " + req.getExerciseId()));
                    return RoutineExercise.builder()
                            .routine(routine)
                            .exercise(exercise)
                            .orderIndex(req.getOrderIndex())
                            .notes(req.getNotes())
                            .build();
                }).collect(Collectors.toList());

        routine.setExercises(routineExercises);
        Routine savedRoutine = routineRepository.save(routine);
        return mapToResponse(savedRoutine);
    }

    @Transactional
    public RoutineResponse updateRoutine(User user, Long routineId, RoutineRequest request) {
        Routine routine = routineRepository.findById(routineId)
                .orElseThrow(() -> new ResourceNotFoundException("Routine not found: " + routineId));
        if (routine.getUser() == null || !routine.getUser().getId().equals(user.getId())) {
            throw new ResourceNotFoundException("Routine not found: " + routineId);
        }
        if (request.getName() != null) routine.setName(request.getName());
        routine.setNotes(request.getNotes());

        routine.getExercises().clear();
        List<RoutineExercise> routineExercises = request.getExercises().stream()
                .map(req -> {
                    Exercise exercise = exerciseRepository.findById(req.getExerciseId())
                            .orElseThrow(() -> new ResourceNotFoundException(
                                    "Exercise not found: " + req.getExerciseId()));
                    return RoutineExercise.builder()
                            .routine(routine)
                            .exercise(exercise)
                            .orderIndex(req.getOrderIndex())
                            .notes(req.getNotes())
                            .build();
                }).collect(Collectors.toList());
        routine.getExercises().addAll(routineExercises);

        return mapToResponse(routineRepository.save(routine));
    }

    public List<RoutineResponse> getUserRoutines(User user) {
        return routineRepository.findTemplatesAndUserRoutines(user).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public List<RoutineResponse> getTemplates() {
        return routineRepository.findByIsTemplateTrue().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    private RoutineResponse mapToResponse(Routine routine) {
        return RoutineResponse.builder()
                .id(routine.getId())
                .name(routine.getName())
                .notes(routine.getNotes())
                .isTemplate(routine.getIsTemplate())
                .exercises(routine.getExercises().stream()
                        .map(re -> RoutineResponse.RoutineExerciseResponse.builder()
                                .id(re.getId())
                                .exerciseId(re.getExercise().getId())
                                .exerciseName(re.getExercise().getName())
                                .orderIndex(re.getOrderIndex())
                                .notes(re.getNotes())
                                .build())
                        .collect(Collectors.toList()))
                .build();
    }
}
