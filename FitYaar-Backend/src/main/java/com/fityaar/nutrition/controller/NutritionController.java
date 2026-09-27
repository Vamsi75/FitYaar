package com.fityaar.nutrition.controller;

import com.fityaar.nutrition.dto.DailyNutritionSummary;
import com.fityaar.nutrition.dto.NutritionEntryRequest;
import com.fityaar.nutrition.dto.NutritionEntryResponse;
import com.fityaar.nutrition.entity.FoodItem;
import com.fityaar.nutrition.service.NutritionService;
import com.fityaar.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * DEFERRED TO NEXT RELEASE. Hidden by default via the {@code fityaar.features.nutrition} flag
 * (see application.yml). Before re-enabling, this controller must be migrated off the hardcoded
 * mock user (id 1L) to {@code @AuthenticationPrincipal}, matching the workout/user controllers.
 */
@RestController
@RequestMapping("/api/nutrition")
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "fityaar.features", name = "nutrition", havingValue = "true", matchIfMissing = false)
public class NutritionController {

    private final NutritionService nutritionService;

    @PostMapping("/log")
    public ResponseEntity<NutritionEntryResponse> logFood(@RequestBody NutritionEntryRequest request) {
        User mockUser = User.builder().id(1L).build(); 
        return ResponseEntity.ok(nutritionService.logFood(mockUser, request));
    }

    @GetMapping("/daily")
    public ResponseEntity<List<NutritionEntryResponse>> getDailyNutrition(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        User mockUser = User.builder().id(1L).build();
        return ResponseEntity.ok(nutritionService.getDailyNutrition(mockUser, date));
    }

    @GetMapping("/summary")
    public ResponseEntity<DailyNutritionSummary> getDailySummary(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        User mockUser = User.builder().id(1L).build();
        return ResponseEntity.ok(nutritionService.getDailySummary(mockUser, date));
    }

    @PostMapping("/water/log")
    public ResponseEntity<Void> logWater(@RequestParam Integer amountMl, 
                                        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        User mockUser = User.builder().id(1L).build();
        nutritionService.logWater(mockUser, amountMl, date);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/food/search")
    public ResponseEntity<List<FoodItem>> searchFood(@RequestParam String query) {
        return ResponseEntity.ok(nutritionService.searchFoodItems(query));
    }
}
