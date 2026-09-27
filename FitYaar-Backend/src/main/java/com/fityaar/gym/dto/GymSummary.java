package com.fityaar.gym.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class GymSummary {
    private Long gymId;
    private String name;
    private String bannerText;
    private Integer capacity;
    private long liveCount;
    private Long membershipId;
    private String role;    // MEMBER / TRAINER / ADMIN
    private String status;  // PENDING / ACTIVE / REJECTED
    private boolean admin;
    private boolean checkedIn;
}
