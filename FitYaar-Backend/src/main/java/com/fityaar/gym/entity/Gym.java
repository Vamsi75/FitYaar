package com.fityaar.gym.entity;

import com.fityaar.common.BaseAuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "gyms")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Gym extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    /** Members enter this to request to join. */
    @Column(name = "join_code", nullable = false, unique = true)
    private String joinCode;

    /** Owners/managers enter this to claim admin of the gym. */
    @Column(name = "owner_code", nullable = false)
    private String ownerCode;

    private Integer capacity;

    @Column(name = "banner_text")
    private String bannerText;

    // --- B2B seat-tier billing (super-admin-driven; active plan grants Pro to active members) ---

    /** Free-form tier label, e.g. STARTER / GROWTH / PRO_UNLIMITED (null = no plan). */
    @Column(name = "plan_tier", length = 24)
    private String planTier;

    @Enumerated(EnumType.STRING)
    @Column(name = "plan_status", length = 16)
    private PlanStatus planStatus;

    /** When the gym plan lapses (null = no expiry). */
    @Column(name = "plan_current_period_end")
    private LocalDateTime planCurrentPeriodEnd;

    /** Seats bought at this tier (advisory — used for over-cap warnings, not enforced). */
    @Column(name = "paid_seats")
    private Integer paidSeats;

    public enum PlanStatus { ACTIVE, SUSPENDED, EXPIRED }
}
