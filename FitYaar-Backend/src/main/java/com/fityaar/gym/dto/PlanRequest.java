package com.fityaar.gym.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;

/** Trainer/admin assigns a structured plan (list of exercises) to a client. */
@Data
public class PlanRequest {
    private Long clientId; // the member this plan is for
    @NotBlank
    private String title;
    private String note; // optional overall note
    private List<PlanItemInput> items;

    @Data
    public static class PlanItemInput {
        private String exerciseName;
        private Integer sets;
        private Integer reps;
        private String note;
    }
}
