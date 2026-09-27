package com.fityaar.gym.dto;

/** A gym trainer/owner shown to members (name always visible). activeNow = checked in right now. */
public record TrainerDto(Long userId, String displayName, String role, boolean activeNow) {}
