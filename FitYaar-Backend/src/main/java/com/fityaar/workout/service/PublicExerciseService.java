package com.fityaar.workout.service;

import com.fityaar.exception.ResourceNotFoundException;
import com.fityaar.workout.dto.PublicExerciseDetail;
import com.fityaar.workout.dto.PublicExerciseSummary;
import com.fityaar.workout.entity.Exercise;
import com.fityaar.workout.entity.Exercise.MuscleGroup;
import com.fityaar.workout.repository.ExerciseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Set;

/**
 * Read-only, unauthenticated exercise catalog for the public website (Phase B).
 * Serves only the shared catalog (non-custom, slug present); the 173-row list is
 * small, so filtering is done in memory.
 */
@Service
@RequiredArgsConstructor
public class PublicExerciseService {

    private final ExerciseRepository exerciseRepository;

    public List<PublicExerciseSummary> list(String query, String muscle, String equipment) {
        final String q = query == null ? "" : query.trim().toLowerCase();
        final String m = normalize(muscle);
        final String eq = normalize(equipment);

        return exerciseRepository.findByIsCustomFalseOrderByName().stream()
                .filter(e -> e.getSlug() != null)
                .filter(e -> q.isEmpty() || e.getName().toLowerCase().contains(q))
                .filter(e -> m == null || matchesMuscle(e, m))
                .filter(e -> eq == null || (e.getEquipment() != null && e.getEquipment().name().equals(eq)))
                .map(this::toSummary)
                .toList();
    }

    public PublicExerciseDetail getBySlug(String slug) {
        Exercise e = exerciseRepository.findBySlugAndIsCustomFalse(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Exercise not found: " + slug));
        return toDetail(e);
    }

    private static String normalize(String value) {
        if (value == null) return null;
        String v = value.trim().toUpperCase();
        return v.isEmpty() ? null : v;
    }

    private boolean matchesMuscle(Exercise e, String muscle) {
        return names(e.getPrimaryMuscleGroups()).contains(muscle)
                || names(e.getSecondaryMuscleGroups()).contains(muscle);
    }

    private static List<String> names(Set<MuscleGroup> groups) {
        if (groups == null) return Collections.emptyList();
        return groups.stream().map(Enum::name).sorted().toList();
    }

    private PublicExerciseSummary toSummary(Exercise e) {
        return PublicExerciseSummary.builder()
                .slug(e.getSlug())
                .name(e.getName())
                .primaryMuscles(names(e.getPrimaryMuscleGroups()))
                .equipment(e.getEquipment() == null ? null : e.getEquipment().name())
                .category(e.getCategory() == null ? null : e.getCategory().name())
                .build();
    }

    private PublicExerciseDetail toDetail(Exercise e) {
        return PublicExerciseDetail.builder()
                .slug(e.getSlug())
                .name(e.getName())
                .description(e.getDescription())
                .primaryMuscles(names(e.getPrimaryMuscleGroups()))
                .secondaryMuscles(names(e.getSecondaryMuscleGroups()))
                .equipment(e.getEquipment() == null ? null : e.getEquipment().name())
                .exerciseType(e.getExerciseType() == null ? null : e.getExerciseType().name())
                .category(e.getCategory() == null ? null : e.getCategory().name())
                .build();
    }
}
