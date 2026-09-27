package com.fityaar.workout.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

/** Full public exercise detail for /exercises/{slug} SEO pages. */
@Data
@Builder
public class PublicExerciseDetail {
    private String slug;
    private String name;
    private String description;
    private List<String> primaryMuscles;
    private List<String> secondaryMuscles;
    private String equipment;
    private String exerciseType;
    private String category;
}
