package com.fityaar.gym.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/** Trainer/admin adds a class to the gym schedule. */
@Data
public class ClassRequest {
    @NotBlank
    private String title;
    private String schedule; // e.g. "Mon & Wed 7:00 PM"
    private String description;
}
