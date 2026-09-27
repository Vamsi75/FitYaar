package com.fityaar.gym.dto;

import java.time.LocalDate;

public record MemberDetail(
        Long membershipId,
        Long userId,
        String displayName,
        String email,
        String phone,
        String role,
        String status,
        LocalDate joinedAt,
        LocalDate expiresAt,
        String trainerName,
        String ptNotes) {}
