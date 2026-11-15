package com.fityaar.workout.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Maps an exercise name used by another app (Hevy, Strong, …) onto a FitYaar catalog exercise.
 * {@code aliasKey} is the normalized name (see {@code ExerciseNameNormalizer}).
 */
@Entity
@Table(name = "exercise_aliases")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExerciseAlias {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "alias_key", nullable = false, unique = true)
    private String aliasKey;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;
}
