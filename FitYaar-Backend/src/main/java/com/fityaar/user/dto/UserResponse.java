package com.fityaar.user.dto;

import com.fityaar.user.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {
    private Long id;
    private String email;
    private String displayName;
    private User.Role role;
    /** Computed FitYaar Pro entitlement (personal sub or gym-sponsored). */
    private boolean pro;
    private String plan;         // MONTHLY | YEARLY | LIFETIME | gym tier; null when free
    private LocalDateTime until; // null = no expiry (LIFETIME / gym plan) or free
}
