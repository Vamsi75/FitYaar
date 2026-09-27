package com.fityaar.social.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CompareStats {
    private String meName;
    private String themName;
    private StatBlock me;
    private StatBlock them;

    @Data
    @Builder
    public static class StatBlock {
        private long workouts;
        private long sets;
        private long volume;
        private long minutes;
    }
}
