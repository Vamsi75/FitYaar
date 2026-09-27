package com.fityaar.gym.dto;

import java.time.LocalDate;
import java.util.List;

public record GymPlanDto(Long id, String title, String body, LocalDate planDate,
                         String authorName, List<PlanItemDto> items) {}
