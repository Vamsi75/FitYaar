package com.fityaar.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/** First password for an account created with Google sign-in. */
@Data
public class SetPasswordRequest {
    @NotBlank
    @Size(min = 8, max = 100, message = "must be at least 8 characters")
    private String newPassword;
}
