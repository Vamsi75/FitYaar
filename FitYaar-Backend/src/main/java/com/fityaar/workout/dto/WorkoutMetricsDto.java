package com.fityaar.workout.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Wearable data for a session (request body of {@code PUT /api/workout/sessions/{id}/metrics}
 * and the {@code healthMetrics} object on session responses). Computed on-device from
 * Health Connect / Apple Health.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutMetricsDto {

    @Pattern(regexp = "HEALTH_CONNECT|APPLE_HEALTH", message = "must be HEALTH_CONNECT or APPLE_HEALTH")
    private String platform;

    @Size(max = 255)
    private String sourceName;

    @Min(25) @Max(250)
    private Integer avgHeartRate;
    @Min(25) @Max(250)
    private Integer maxHeartRate;
    @Min(25) @Max(250)
    private Integer minHeartRate;

    @Min(0) @Max(20000)
    private Integer activeCalories;

    /** Total (active + resting) calories, when the watch doesn't report active calories. */
    @Min(0) @Max(20000)
    private Integer totalCalories;

    @Min(100) @Max(250)
    private Integer maxHrUsed;

    /** Seconds in zones 1–5 (50–60, 60–70, 70–80, 80–90, 90+ % of HRmax). */
    @Size(max = 5)
    private List<@Min(0) Integer> zoneSeconds;

    /** [[offsetSeconds, bpm], ...] — down-sampled by the app. */
    @Size(max = 600)
    private List<@Size(min = 2, max = 2) List<Integer>> heartRateSamples;
}
