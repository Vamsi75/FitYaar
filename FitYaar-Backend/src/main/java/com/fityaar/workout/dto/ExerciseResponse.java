package com.fityaar.workout.dto;

import com.fityaar.workout.entity.Exercise;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExerciseResponse {
    private Long id;
    private String name;
    private String description;
    private Set<Exercise.MuscleGroup> primaryMuscleGroups;
    private Set<Exercise.MuscleGroup> secondaryMuscleGroups;
    private Exercise.Equipment equipment;
    private Exercise.ExerciseType exerciseType;
    private Exercise.Category category;
    private Boolean isCustom;
}
