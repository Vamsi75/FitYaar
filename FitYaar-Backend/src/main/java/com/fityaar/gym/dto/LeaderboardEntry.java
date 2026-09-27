package com.fityaar.gym.dto;

/** One row of the weekly gym leaderboard (last 7 days). */
public record LeaderboardEntry(Long userId, String displayName, long workouts, long volume) {}
