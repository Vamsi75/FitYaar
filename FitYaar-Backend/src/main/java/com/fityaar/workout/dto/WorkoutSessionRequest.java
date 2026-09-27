package com.fityaar.workout.dto;

import com.fityaar.workout.entity.SetEntry;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutSessionRequest {
    private String name;
    private Long routineId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String notes;
    private List<WorkoutExerciseRequest> exercises;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WorkoutExerciseRequest {
        private Long exerciseId;
        private Integer orderIndex;
        private String notes;
        private List<SetEntryRequest> sets;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SetEntryRequest {
        private Integer orderIndex;
        private Double weight;
        private Integer reps;
        private Integer rpe;
        private Integer durationSeconds;
        private Double distanceMeters;
        private SetEntry.SetType type;
        private Boolean isCompleted;
    }
}
