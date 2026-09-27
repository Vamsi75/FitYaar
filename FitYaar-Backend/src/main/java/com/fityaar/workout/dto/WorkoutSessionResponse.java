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
public class WorkoutSessionResponse {
    private Long id;
    private String name;
    private Long routineId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String notes;
    private List<WorkoutExerciseResponse> exercises;
    private Integer totalVolume;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WorkoutExerciseResponse {
        private Long id;
        private Long exerciseId;
        private String exerciseName;
        private String exerciseType;
        private Integer orderIndex;
        private String notes;
        private List<SetEntryResponse> sets;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SetEntryResponse {
        private Long id;
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
