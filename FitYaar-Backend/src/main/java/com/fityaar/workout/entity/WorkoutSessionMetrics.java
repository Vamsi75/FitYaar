package com.fityaar.workout.entity;

import com.fityaar.common.BaseAuditEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * Wearable data for one logged session, read on-device from Health Connect / Apple Health
 * and uploaded by the app. Keyed by the session id (one row per session).
 */
@Entity
@Table(name = "workout_session_metrics")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkoutSessionMetrics extends BaseAuditEntity {

    @Id
    @Column(name = "session_id")
    private Long sessionId;

    @Enumerated(EnumType.STRING)
    @Column(length = 30)
    private Platform platform;

    private String sourceName;

    private Integer avgHeartRate;
    private Integer maxHeartRate;
    private Integer minHeartRate;
    private Integer activeCalories;
    /** Total (active + resting) calories — what Fitbit writes to Health Connect. */
    private Integer totalCalories;

    /** The HRmax the zone split was computed against. */
    @Column(name = "max_hr_used")
    private Integer maxHrUsed;

    @Column(name = "zone1_seconds")
    private Integer zone1Seconds;
    @Column(name = "zone2_seconds")
    private Integer zone2Seconds;
    @Column(name = "zone3_seconds")
    private Integer zone3Seconds;
    @Column(name = "zone4_seconds")
    private Integer zone4Seconds;
    @Column(name = "zone5_seconds")
    private Integer zone5Seconds;

    /** JSON {@code [[offsetSeconds, bpm], ...]}, down-sampled for charts. */
    @Column(columnDefinition = "TEXT")
    private String heartRateSamples;

    public enum Platform {
        HEALTH_CONNECT, APPLE_HEALTH
    }
}
