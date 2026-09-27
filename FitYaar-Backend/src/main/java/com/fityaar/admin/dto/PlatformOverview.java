package com.fityaar.admin.dto;

import lombok.Builder;
import lombok.Data;

import java.util.Map;

/** Platform-wide snapshot for the management dashboard landing page. */
@Data
@Builder
public class PlatformOverview {

    // Users
    private long totalUsers;
    private long activeUsers;
    private long suspendedUsers;
    private long newUsers7d;
    private long newUsers30d;

    // Gyms & membership
    private long totalGyms;
    private long gymsWithActivePlan;
    private long totalOwners;
    private long totalTrainers;
    private long activeMembers;
    private long liveCheckins;

    // Engagement
    private long workouts24h;
    private long workouts7d;
    private long workouts30d;
    private long totalWorkouts;

    // Monetization
    private long activeProSubscribers;
    private Map<String, Long> subsByPlan;
    private Map<String, Long> subsBySource;
    /** Advisory monthly-recurring estimate from the config price map (0 until prices configured). */
    private long estimatedMrrPaise;

    // Alerts (things needing attention)
    private long gymsOverCap;
    private long plansExpiringSoon;
    private long subsExpiringSoon;
}
