package com.fityaar.workout.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "set_entries")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SetEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "workout_exercise_id", nullable = false)
    private WorkoutExercise workoutExercise;

    private Integer orderIndex;

    private Double weight;
    private Integer reps;
    private Integer rpe;

    /** For time-based sets (planks, cardio holds). */
    private Integer durationSeconds;
    /** For distance-based sets (running, carries, rowing). */
    private Double distanceMeters;

    @Enumerated(EnumType.STRING)
    private SetType type = SetType.NORMAL;

    private Boolean isCompleted = false;

    public enum SetType {
        NORMAL, WARMUP, DROPSET, FAILURE
    }
}

