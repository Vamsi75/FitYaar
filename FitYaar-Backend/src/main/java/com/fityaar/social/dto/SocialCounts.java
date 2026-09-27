package com.fityaar.social.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class SocialCounts {
    private long followers;
    private long following;
    private long pendingRequests;
}
