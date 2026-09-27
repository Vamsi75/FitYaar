package com.fityaar.nutrition.entity;

import com.fityaar.common.BaseAuditEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "food_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FoodItem extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    private String brand;

    private Double servingSize;
    private String servingUnit; // e.g., "g", "ml", "piece"
    private String portionName; // e.g., "Small", "Medium", "Large", "1 cup"

    private Double calories;
    private Double protein;
    private Double carbs;
    private Double fat;
    private Double fiber;
}

