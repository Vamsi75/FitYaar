package com.fityaar.subscription.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/** Request bodies for the subscription endpoints. */
public class SubscriptionRequests {

    @Data
    public static class GrantRequest {
        @NotBlank
        private String email;
        @NotBlank
        private String plan;   // MONTHLY | YEARLY | LIFETIME
    }

    @Data
    public static class RedeemRequest {
        @NotBlank
        private String code;
    }
}
