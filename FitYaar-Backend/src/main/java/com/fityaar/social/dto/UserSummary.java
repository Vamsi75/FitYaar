package com.fityaar.social.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UserSummary {
    private Long userId;
    private String displayName;
    private String profilePictureUrl;
    private boolean isPublic;
    private String followStatus; // NONE / PENDING / FOLLOWING
}
