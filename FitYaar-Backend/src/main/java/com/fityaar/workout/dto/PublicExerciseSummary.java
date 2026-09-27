package com.fityaar.workout.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

/** Lightweight exercise card for the public web library list/grid. */
@Data
@Builder
public class PublicExerciseSummary {
    private String slug;
    private String name;
    private List<String> primaryMuscles;
    private String equipment;
    private String category;
}
