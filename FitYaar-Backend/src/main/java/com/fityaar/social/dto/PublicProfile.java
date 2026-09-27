package com.fityaar.social.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class PublicProfile {
    private Long userId;
    private String displayName;
    private String bio;
    private String profilePictureUrl;
    private boolean isPublic;
    private long followersCount;
    private long followingCount;
    private long workoutsCount;
    private String followStatus; // NONE / PENDING / FOLLOWING
    private boolean canView;     // may see workouts/compare
    private boolean self;
}
