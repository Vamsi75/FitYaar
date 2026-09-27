package com.fityaar.admin.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/** One row in the management portal's subscriptions table. */
@Data
@Builder
public class AdminSubscriptionRow {
    private Long id;
    private Long userId;
    private String email;
    private String displayName;
    private String source;
    private String plan;
    private String status;
    private LocalDateTime currentPeriodEnd;
    private String providerRef;
    private LocalDateTime createdAt;
}
