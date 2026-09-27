package com.fityaar.gym.entity;

import jakarta.persistence.*;
import lombok.*;

/** One exercise line in a trainer-assigned plan (shown to the client read-only). */
@Entity
@Table(name = "gym_plan_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GymPlanItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "plan_id", nullable = false)
    private GymPlan plan;

    @Column(name = "order_index", nullable = false)
    private int orderIndex;

    @Column(name = "exercise_name", nullable = false, length = 160)
    private String exerciseName;

    private Integer sets;
    private Integer reps;

    @Column(length = 255)
    private String note;
}
