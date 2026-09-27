package com.fityaar.nutrition.dto;

import com.fityaar.nutrition.entity.NutritionEntry.MealType;
import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NutritionEntryResponse {
    private Long id;
    private Long foodItemId;
    private String foodName;
    private String portionName;
    private Double quantity;
    private LocalDate date;
    private MealType mealType;
    
    // Calculated total nutrients based on quantity
    private Double totalCalories;
    private Double totalProtein;
    private Double totalCarbs;
    private Double totalFat;
    private Double totalFiber;
}
