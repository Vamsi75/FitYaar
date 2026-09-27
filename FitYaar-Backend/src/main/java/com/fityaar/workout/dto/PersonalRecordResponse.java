package com.fityaar.workout.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PersonalRecordResponse {
    private Long id;
    private Long exerciseId;
    private String exerciseName;
    private Double weight;
    private Integer reps;
    private Double oneRepMaxEstimate;
    private LocalDate achievedDate;
}
