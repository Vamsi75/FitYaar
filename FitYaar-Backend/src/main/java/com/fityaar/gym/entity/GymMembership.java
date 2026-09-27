package com.fityaar.gym.entity;

import com.fityaar.common.BaseAuditEntity;
import com.fityaar.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "gym_memberships",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "gym_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GymMembership extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne
    @JoinColumn(name = "gym_id", nullable = false)
    private Gym gym;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status;

    /** Membership validity (null = no expiry set). */
    @Column(name = "expires_at")
    private LocalDate expiresAt;

    /** The member's personal trainer (null = not a PT client). */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trainer_id")
    private User trainer;

    @Column(name = "pt_notes", columnDefinition = "text")
    private String ptNotes;

    public enum Role { MEMBER, TRAINER, OWNER }

    public enum Status { PENDING, ACTIVE, REJECTED, INACTIVE }
}
