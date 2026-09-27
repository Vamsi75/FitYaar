package com.fityaar.workout.entity;

import com.fityaar.common.BaseAuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.Set;

@Entity
@Table(name = "exercises")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Exercise extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    /** SEO-friendly slug for the public web library (e.g. "bench-press-barbell").
     *  Populated for catalog exercises (V18); NULL for custom user exercises. */
    private String slug;

    private String description;

    @ElementCollection(targetClass = MuscleGroup.class)
    @CollectionTable(name = "exercise_primary_muscle_groups", joinColumns = @JoinColumn(name = "exercise_id"))
    @Column(name = "muscle_group")
    @Enumerated(EnumType.STRING)
    private Set<MuscleGroup> primaryMuscleGroups;

    @ElementCollection(targetClass = MuscleGroup.class)
    @CollectionTable(name = "exercise_secondary_muscle_groups", joinColumns = @JoinColumn(name = "exercise_id"))
    @Column(name = "muscle_group")
    @Enumerated(EnumType.STRING)
    private Set<MuscleGroup> secondaryMuscleGroups;

    @Enumerated(EnumType.STRING)
    private Equipment equipment;

    @Enumerated(EnumType.STRING)
    private ExerciseType exerciseType;

    private Boolean isCustom = false;

    @Column(name = "created_by_user_id")
    private Long createdByUserId;

    @Enumerated(EnumType.STRING)
    private Category category;

    public enum MuscleGroup {
        UPPER_CHEST, CHEST, LOWER_CHEST,
        FRONT_DELTS, SIDE_DELTS, REAR_DELTS,
        BICEPS, TRICEPS, FOREARMS,
        LATS, UPPER_BACK, TRAPS, LOWER_BACK,
        ABS, OBLIQUES,
        QUADRICEPS, HAMSTRINGS, GLUTES, CALVES,
        NECK
    }

    public enum Equipment {
        DUMBBELL, BARBELL, KETTLEBELL, MACHINE, PLATE, SUSPENSION_BAND, BAND, CABLE, NO_EQUIPMENT, OTHER
    }

    public enum ExerciseType {
        WEIGHT_REPS, BODYWEIGHT_REPS, WEIGHTED_BODYWEIGHT_REPS, ASSISTED_BODYWEIGHT_REPS,
        DURATION, DURATION_WEIGHT, DISTANCE_DURATION, WEIGHT_DISTANCE
    }

    public enum Category {
        STRENGTH, CARDIO, BODYWEIGHT, WEIGHTED_BODYWEIGHT, ASSISTED_BODYWEIGHT
    }
}

