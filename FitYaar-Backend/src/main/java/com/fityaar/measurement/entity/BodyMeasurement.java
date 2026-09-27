package com.fityaar.measurement.entity;

import com.fityaar.common.BaseAuditEntity;
import com.fityaar.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

/** One user's body metrics for a given day (one row per day — see the unique key). */
@Entity
@Table(name = "body_measurements")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BodyMeasurement extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "measured_on", nullable = false)
    private LocalDate measuredOn;

    @Column(name = "weight_kg")
    private Double weightKg;

    @Column(name = "waist_cm")
    private Double waistCm;

    @Column(name = "body_fat_pct")
    private Double bodyFatPct;
}
