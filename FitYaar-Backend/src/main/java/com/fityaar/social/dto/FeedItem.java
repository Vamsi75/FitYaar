package com.fityaar.social.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class FeedItem {
    private Long sessionId;
    private String name;
    private LocalDateTime startTime;
    private int exercisesCount;
    private int sets;
    private int volume;
    private Long authorId;
    private String authorName;
}
