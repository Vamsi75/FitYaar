package com.fityaar.social.entity;

import com.fityaar.common.BaseAuditEntity;
import com.fityaar.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "follows",
        uniqueConstraints = @UniqueConstraint(columnNames = {"follower_id", "following_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Follow extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** The user who follows. */
    @ManyToOne
    @JoinColumn(name = "follower_id", nullable = false)
    private User follower;

    /** The user being followed. */
    @ManyToOne
    @JoinColumn(name = "following_id", nullable = false)
    private User following;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status;

    /** ACCEPTED immediately for public accounts; PENDING (a request) for private ones. */
    public enum Status { PENDING, ACCEPTED }
}
