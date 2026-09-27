package com.fityaar.gym.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.time.LocalDateTime;

/** Request bodies for the platform super-admin endpoints. */
public class AdminRequests {

    @Data
    public static class GymBillingRequest {
        /** Tier label, e.g. STARTER / GROWTH / PRO_UNLIMITED (null clears the plan). */
        private String planTier;
        /** ACTIVE | SUSPENDED | EXPIRED (null clears status). */
        private String planStatus;
        private LocalDateTime planCurrentPeriodEnd;
        private Integer paidSeats;
    }

    @Data
    public static class ClaimRequest {
        @NotBlank
        private String code;
    }

    @Data
    public static class CreateGymRequest {
        @NotBlank
        private String name;
        private Integer capacity;
        @NotBlank
        private String joinCode;
        @NotBlank
        private String ownerCode;
    }

    @Data
    public static class AssignAdminRequest {
        @NotBlank
        private String email;
    }

    @Data
    public static class UserEmailRequest {
        @NotBlank
        private String email;
    }
}
