package com.fityaar.gym.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/** Seat utilization for a gym's B2B plan (super-admin view). */
@Data
@Builder
public class GymSeatUtilization {
    private Long gymId;
    private String name;
    private String planTier;
    private String planStatus;
    private LocalDateTime planCurrentPeriodEnd;
    private Integer paidSeats;
    private long activeMembers;
    private boolean overCap;
}
