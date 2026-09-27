package com.fityaar.user.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class GoogleRequest {
    @NotBlank
    private String idToken;
}
