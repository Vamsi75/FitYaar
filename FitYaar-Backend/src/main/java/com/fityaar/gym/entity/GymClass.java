package com.fityaar.gym.entity;

import com.fityaar.common.BaseAuditEntity;
import com.fityaar.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

/** A recurring class a trainer runs at a gym (simple schedule, no booking yet). */
@Entity
@Table(name = "gym_classes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GymClass extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "gym_id", nullable = false)
    private Gym gym;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trainer_id", nullable = false)
    private User trainer;

    @Column(nullable = false, length = 160)
    private String title;

    @Column(length = 120)
    private String schedule; // e.g. "Mon & Wed 7:00 PM"

    @Column(columnDefinition = "text")
    private String description;
}
