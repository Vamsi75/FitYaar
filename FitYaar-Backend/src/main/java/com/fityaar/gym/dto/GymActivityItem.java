package com.fityaar.gym.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class GymActivityItem {
    private String label; // e.g. "Chest"
    private long count;
}
