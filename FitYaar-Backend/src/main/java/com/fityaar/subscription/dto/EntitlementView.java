package com.fityaar.subscription.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/** The computed Pro entitlement for a user. */
@Data
@Builder
public class EntitlementView {
    private boolean pro;
    private String plan;        // MONTHLY | YEARLY | LIFETIME, or the gym tier; null when free
    private String source;      // RAZORPAY | MANUAL | PROMO | GYM; null when free
    private LocalDateTime until; // null = no expiry (LIFETIME / gym plan) or free
}
