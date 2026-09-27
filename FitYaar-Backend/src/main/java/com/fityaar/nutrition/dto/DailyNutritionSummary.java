package com.fityaar.nutrition.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyNutritionSummary {
    private Double dailyCalorieGoal;
    private Double totalCaloriesConsumed;
    private Double calorieProgressPercentage;

    private Double totalProtein;
    private Double totalCarbs;
    private Double totalFat;
    private Double totalFiber;

    private Double dailyWaterGoalMl;
    private Integer totalWaterConsumedMl;
    private Double waterProgressPercentage;
}
