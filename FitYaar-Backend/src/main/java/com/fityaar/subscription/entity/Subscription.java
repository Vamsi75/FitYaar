package com.fityaar.subscription.entity;

import com.fityaar.common.BaseAuditEntity;
import com.fityaar.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * A personal FitYaar Pro subscription. Gym-sponsored Pro is NOT stored here — it is
 * derived from the user's gym plan (see {@code EntitlementService}).
 */
@Entity
@Table(name = "subscriptions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Subscription extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Source source;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Plan plan;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Status status;

    /** Null for LIFETIME (never expires). */
    @Column(name = "current_period_end")
    private LocalDateTime currentPeriodEnd;

    @Column(name = "provider_ref", length = 128)
    private String providerRef;

    public enum Source { RAZORPAY, MANUAL, PROMO }

    public enum Plan { MONTHLY, YEARLY, LIFETIME }

    public enum Status { ACTIVE, CANCELLED, EXPIRED }
}
