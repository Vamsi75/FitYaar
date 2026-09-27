package com.fityaar.gym.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/** Gym view for the platform super-admin (includes the codes + B2B plan state). */
@Data
@Builder
public class GymAdminDto {
    private Long id;
    private String name;
    private String joinCode;
    private String ownerCode;
    private Integer capacity;
    private String planTier;
    private String planStatus;
    private LocalDateTime planCurrentPeriodEnd;
    private Integer paidSeats;
}
