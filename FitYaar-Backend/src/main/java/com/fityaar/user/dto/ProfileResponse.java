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
public class ProfileResponse {
    private Long id;
    private String email;
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
    private String gender;
    private LocalDate birthday;
    private String instagram;
    private String website;
    private String phone;

    // Preferences
    private String theme;
    private String language;
    private String weightUnit;
    private String distanceUnit;
    private String measurementUnit;
}
