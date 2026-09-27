package com.fityaar.audit.entity;

import com.fityaar.common.BaseAuditEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * One immutable line in the platform's action audit trail. Written fail-soft by
 * {@link com.fityaar.audit.service.AuditService} — a logging failure never breaks the guarded action.
 */
@Entity
@Table(name = "audit_logs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuditLog extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Who acted (null = system). Denormalized email kept so the line survives user deletion. */
    @Column(name = "actor_id")
    private Long actorId;

    @Column(name = "actor_email")
    private String actorEmail;

    @Column(nullable = false, length = 64)
    private String action;

    @Column(name = "resource_type", length = 64)
    private String resourceType;

    @Column(name = "resource_id", length = 64)
    private String resourceId;

    @Column(name = "gym_id")
    private Long gymId;

    /** JSON blob of extra context (serialized by AuditService). */
    @Column(columnDefinition = "text")
    private String metadata;

    @Column(length = 64)
    private String ip;
}
