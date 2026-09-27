package com.fityaar.gym.dto;

import lombok.Data;

import java.time.LocalDate;

/** Trainer/admin edits a member's gym record (triggers a notification). */
@Data
public class MemberUpdateRequest {
    private String phone;
    private LocalDate expiresAt;
    private String ptNotes;
}
