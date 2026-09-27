package com.fityaar.user.entity;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fityaar.common.BaseAuditEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Profile extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false)
    @JsonBackReference
    private User user;

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
    private Double dailyWaterGoal; // in ml

    private Boolean isPublic = true;

    /** Whether this member appears in gym active-now / leaderboard. */
    @Column(name = "gym_visible", nullable = false)
    private Boolean gymVisible = true;

    // Private (not shown on public profiles)
    private String gender;
    private LocalDate birthday;

    private String phone;

    // Social links
    private String instagram;
    private String website;
}

