package com.fityaar.gym.dto;

/** Check-in count for one hour of the day (0–23), aggregated over recent days. */
public record HourlyBucket(int hour, long count) {}
