package com.fityaar.gym.entity;

import com.fityaar.common.BaseAuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "gym_events")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GymEvent extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "gym_id", nullable = false)
    private Gym gym;

    @Column(nullable = false)
    private String title;

    private String body;

    @Column(name = "starts_at")
    private LocalDateTime startsAt;
}
