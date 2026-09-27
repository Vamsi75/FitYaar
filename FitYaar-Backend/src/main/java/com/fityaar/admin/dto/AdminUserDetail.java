package com.fityaar.admin.dto;

import com.fityaar.gym.dto.MembershipView;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Operational detail for one user. Deliberately a privacy-minimal subset — platform admin needs
 * account/membership/billing context, not the user's full fitness history.
 */
@Data
@Builder
public class AdminUserDetail {
    private Long id;
    private String email;
    private String role;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Profile (operational subset)
    private String displayName;
    private String phone;
    private String gender;
    private LocalDate birthday;
    private String fitnessGoal;

    // Entitlement (Pro)
    private boolean pro;
    private String plan;
    private String source;
    private LocalDateTime proUntil;

    // Activity
    private long workoutCount;

    // Gym memberships
    private List<MembershipView> memberships;
}
