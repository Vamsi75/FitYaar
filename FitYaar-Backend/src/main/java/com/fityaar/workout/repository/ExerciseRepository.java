package com.fityaar.workout.repository;

import com.fityaar.workout.entity.Exercise;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ExerciseRepository extends JpaRepository<Exercise, Long> {
    List<Exercise> findByNameContainingIgnoreCase(String name);
    List<Exercise> findByIsCustomFalse();
    List<Exercise> findByCreatedByUserId(Long userId);

    /** Public web library: the shared catalog, alphabetised. */
    List<Exercise> findByIsCustomFalseOrderByName();

    /** Public web library: resolve a catalog exercise by its SEO slug. */
    Optional<Exercise> findBySlugAndIsCustomFalse(String slug);

    @org.springframework.data.jpa.repository.Query("SELECT e FROM Exercise e WHERE (e.isCustom = false OR e.createdByUserId = :userId) AND LOWER(e.name) LIKE LOWER(CONCAT('%', :name, '%'))")
    List<Exercise> searchExercises(Long userId, String name);

    @org.springframework.data.jpa.repository.Query("SELECT e FROM Exercise e WHERE e.isCustom = false OR e.createdByUserId = :userId")
    List<Exercise> findVisible(Long userId);
}
