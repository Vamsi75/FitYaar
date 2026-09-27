package com.fityaar.workout.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoutineResponse {
    private Long id;
    private String name;
    private String notes;
    private List<RoutineExerciseResponse> exercises;
    private Boolean isTemplate;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RoutineExerciseResponse {
        private Long id;
        private Long exerciseId;
        private String exerciseName;
        private Integer orderIndex;
        private String notes;
    }
}
