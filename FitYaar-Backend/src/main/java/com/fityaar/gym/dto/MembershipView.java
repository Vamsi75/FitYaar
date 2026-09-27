package com.fityaar.gym.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;

@Data
@Builder
public class MembershipView {
    private Long membershipId;
    private Long userId;
    private String displayName;
    private String email;
    private String role;
    private String status;
    private LocalDate joinedAt;
    /** Populated for admin cross-gym views (null on single-gym responses). */
    private Long gymId;
    private String gymName;
}
