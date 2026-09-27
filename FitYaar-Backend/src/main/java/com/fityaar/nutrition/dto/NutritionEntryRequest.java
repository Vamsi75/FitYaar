package com.fityaar.nutrition.dto;

import com.fityaar.nutrition.entity.NutritionEntry.MealType;
import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NutritionEntryRequest {
    private Long foodItemId;
    private LocalDate date;
    private MealType mealType;
    private Double quantity;
}
