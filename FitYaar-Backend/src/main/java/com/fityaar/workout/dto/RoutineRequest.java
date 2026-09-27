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
public class RoutineRequest {
    private String name;
    private String notes;
    private List<RoutineExerciseRequest> exercises;
    private Boolean isTemplate;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RoutineExerciseRequest {
        private Long exerciseId;
        private Integer orderIndex;
        private String notes;
    }
}
