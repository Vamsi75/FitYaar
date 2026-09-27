package com.fityaar.workout.controller;

import com.fityaar.security.UserPrincipal;
import com.fityaar.user.entity.User;
import com.fityaar.workout.dto.ExerciseResponse;
import com.fityaar.workout.dto.PersonalRecordResponse;
import com.fityaar.workout.dto.RoutineRequest;
import com.fityaar.workout.dto.RoutineResponse;
import com.fityaar.workout.dto.WorkoutSessionRequest;
import com.fityaar.workout.dto.WorkoutSessionResponse;
import com.fityaar.workout.service.RoutineService;
import com.fityaar.workout.service.WorkoutService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/workout")
@RequiredArgsConstructor
public class WorkoutController {

    private final WorkoutService workoutService;
    private final RoutineService routineService;

    @GetMapping("/exercises")
    public ResponseEntity<List<ExerciseResponse>> searchExercises(
            @RequestParam(required = false, defaultValue = "") String query,
            @RequestParam(required = false) String muscle,
            @RequestParam(required = false) String equipment,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(
                workoutService.searchExercises(principal.getUser(), query, muscle, equipment));
    }

    @PostMapping("/routines")
    public ResponseEntity<RoutineResponse> createRoutine(
            @Valid @RequestBody RoutineRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(routineService.createRoutine(principal.getUser(), request));
    }

    @GetMapping("/routines")
    public ResponseEntity<List<RoutineResponse>> getUserRoutines(
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(routineService.getUserRoutines(principal.getUser()));
    }

    @PutMapping("/routines/{id}")
    public ResponseEntity<RoutineResponse> updateRoutine(
            @PathVariable Long id,
            @Valid @RequestBody RoutineRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(routineService.updateRoutine(principal.getUser(), id, request));
    }

    @GetMapping("/routines/templates")
    public ResponseEntity<List<RoutineResponse>> getTemplates() {
        return ResponseEntity.ok(routineService.getTemplates());
    }

    @PostMapping("/sessions")
    public ResponseEntity<WorkoutSessionResponse> startSession(
            @Valid @RequestBody WorkoutSessionRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(workoutService.startSession(principal.getUser(), request));
    }

    @GetMapping("/history")
    public ResponseEntity<List<WorkoutSessionResponse>> getHistory(
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(workoutService.getUserHistory(principal.getUser()));
    }

    @PutMapping("/sessions/{id}")
    public ResponseEntity<WorkoutSessionResponse> updateSession(
            @PathVariable Long id,
            @Valid @RequestBody WorkoutSessionRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(workoutService.updateSession(principal.getUser(), id, request));
    }

    @DeleteMapping("/sessions/{id}")
    public ResponseEntity<Void> deleteSession(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        workoutService.deleteSession(principal.getUser(), id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/prs")
    public ResponseEntity<List<PersonalRecordResponse>> getUserPRs(
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(workoutService.getUserPRs(principal.getUser()));
    }
}
