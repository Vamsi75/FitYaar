package com.fityaar.nutrition.service;

import com.fityaar.nutrition.dto.DailyNutritionSummary;
import com.fityaar.nutrition.dto.NutritionEntryRequest;
import com.fityaar.nutrition.dto.NutritionEntryResponse;
import com.fityaar.nutrition.entity.FoodItem;
import com.fityaar.nutrition.entity.NutritionEntry;
import com.fityaar.nutrition.entity.WaterEntry;
import com.fityaar.nutrition.repository.FoodItemRepository;
import com.fityaar.nutrition.repository.NutritionEntryRepository;
import com.fityaar.nutrition.repository.WaterEntryRepository;
import com.fityaar.user.entity.Profile;
import com.fityaar.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class NutritionService {

    private final NutritionEntryRepository nutritionEntryRepository;
    private final FoodItemRepository foodItemRepository;
    private final WaterEntryRepository waterEntryRepository;

    @Transactional
    public NutritionEntryResponse logFood(User user, NutritionEntryRequest request) {
        FoodItem foodItem = foodItemRepository.findById(request.getFoodItemId())
                .orElseThrow(() -> new RuntimeException("Food item not found"));

        NutritionEntry entry = NutritionEntry.builder()
                .user(user)
                .foodItem(foodItem)
                .date(request.getDate() != null ? request.getDate() : LocalDate.now())
                .mealType(request.getMealType())
                .quantity(request.getQuantity() != null ? request.getQuantity() : 1.0)
                .build();

        NutritionEntry savedEntry = nutritionEntryRepository.save(entry);
        return mapToResponse(savedEntry);
    }

    public List<NutritionEntryResponse> getDailyNutrition(User user, LocalDate date) {
        return nutritionEntryRepository.findByUserAndDate(user, date).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public DailyNutritionSummary getDailySummary(User user, LocalDate date) {
        List<NutritionEntry> foodEntries = nutritionEntryRepository.findByUserAndDate(user, date);
        List<WaterEntry> waterEntries = waterEntryRepository.findByUserAndDate(user, date);

        Double totalCalories = foodEntries.stream().mapToDouble(e -> e.getFoodItem().getCalories() * e.getQuantity()).sum();
        Double totalProtein = foodEntries.stream().mapToDouble(e -> e.getFoodItem().getProtein() * e.getQuantity()).sum();
        Double totalCarbs = foodEntries.stream().mapToDouble(e -> e.getFoodItem().getCarbs() * e.getQuantity()).sum();
        Double totalFat = foodEntries.stream().mapToDouble(e -> e.getFoodItem().getFat() * e.getQuantity()).sum();
        Double totalFiber = foodEntries.stream().mapToDouble(e -> e.getFoodItem().getFiber() * e.getQuantity()).sum();

        Integer totalWater = waterEntries.stream().mapToInt(WaterEntry::getAmountMl).sum();

        Profile profile = user.getProfile();
        Double calorieGoal = (profile != null && profile.getDailyCalorieGoal() != null) ? profile.getDailyCalorieGoal() : 2000.0;
        Double waterGoal = (profile != null && profile.getDailyWaterGoal() != null) ? profile.getDailyWaterGoal() : 2500.0;

        return DailyNutritionSummary.builder()
                .dailyCalorieGoal(calorieGoal)
                .totalCaloriesConsumed(totalCalories)
                .calorieProgressPercentage(calorieGoal > 0 ? (totalCalories / calorieGoal) * 100 : 0.0)
                .totalProtein(totalProtein)
                .totalCarbs(totalCarbs)
                .totalFat(totalFat)
                .totalFiber(totalFiber)
                .dailyWaterGoalMl(waterGoal)
                .totalWaterConsumedMl(totalWater)
                .waterProgressPercentage(waterGoal > 0 ? (totalWater / waterGoal) * 100 : 0.0)
                .build();
    }

    @Transactional
    public void logWater(User user, Integer amountMl, LocalDate date) {
        WaterEntry entry = WaterEntry.builder()
                .user(user)
                .amountMl(amountMl)
                .date(date != null ? date : LocalDate.now())
                .build();
        waterEntryRepository.save(entry);
    }

    public List<FoodItem> searchFoodItems(String query) {
        return foodItemRepository.findByNameContainingIgnoreCase(query);
    }

    private NutritionEntryResponse mapToResponse(NutritionEntry entry) {
        FoodItem food = entry.getFoodItem();
        Double qty = entry.getQuantity();

        return NutritionEntryResponse.builder()
                .id(entry.getId())
                .foodItemId(food.getId())
                .foodName(food.getName())
                .portionName(food.getPortionName())
                .quantity(qty)
                .date(entry.getDate())
                .mealType(entry.getMealType())
                .totalCalories(food.getCalories() * qty)
                .totalProtein(food.getProtein() * qty)
                .totalCarbs(food.getCarbs() * qty)
                .totalFat(food.getFat() * qty)
                .totalFiber(food.getFiber() * qty)
                .build();
    }
}
