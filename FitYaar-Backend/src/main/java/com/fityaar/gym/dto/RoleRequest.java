package com.fityaar.gym.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/** Admin changes a member's role (MEMBER / TRAINER / ADMIN). */
@Data
public class RoleRequest {
    @NotBlank
    private String role;
}
