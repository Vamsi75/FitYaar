package com.fityaar.workout.controller;

import com.fityaar.workout.dto.PublicExerciseDetail;
import com.fityaar.workout.dto.PublicExerciseSummary;
import com.fityaar.workout.service.PublicExerciseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * Public, unauthenticated exercise catalog for the website's SEO library.
 * Whitelisted in SecurityConfig ({@code /api/public/**}). Read-only; cacheable.
 */
@RestController
@RequestMapping("/api/public/exercises")
@RequiredArgsConstructor
public class PublicExerciseController {

    private final PublicExerciseService publicExerciseService;

    private static final CacheControl CACHE =
            CacheControl.maxAge(1, TimeUnit.HOURS).cachePublic();

    @GetMapping
    public ResponseEntity<List<PublicExerciseSummary>> list(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) String muscle,
            @RequestParam(required = false) String equipment) {
        return ResponseEntity.ok()
                .cacheControl(CACHE)
                .body(publicExerciseService.list(query, muscle, equipment));
    }

    @GetMapping("/{slug}")
    public ResponseEntity<PublicExerciseDetail> get(@PathVariable String slug) {
        return ResponseEntity.ok()
                .cacheControl(CACHE)
                .body(publicExerciseService.getBySlug(slug));
    }
}
