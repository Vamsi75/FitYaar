package com.fityaar.user.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProfileRequest {
    private String displayName;
    private String profilePictureUrl;
    private String bio;
    private String fitnessGoal;
    private Double currentWeight;
    private Double targetWeight;
    private Double height;
    private Double waist;
    private Double bodyFatPercentage;
    private Double dailyCalorieGoal;
    private Double dailyWaterGoal;
    private Boolean isPublic;
    private Boolean gymVisible;

    // Private
    private String gender;
    private LocalDate birthday;

    private String phone;

    // Social links
    private String instagram;
    private String website;

    // Preferences
    private String theme;
    private String language;
    private String weightUnit;
    private String distanceUnit;
    private String measurementUnit;
}
