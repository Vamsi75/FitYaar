package com.fityaar.gym.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class GymEventDto {
    private Long id;
    private String title;
    private String body;
    private LocalDateTime startsAt;
    private LocalDateTime createdAt;
}
