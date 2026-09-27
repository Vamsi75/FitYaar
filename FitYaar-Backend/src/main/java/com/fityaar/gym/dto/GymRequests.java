package com.fityaar.gym.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.time.LocalDateTime;

/** Small request bodies for the gym endpoints. */
public class GymRequests {

    @Data
    public static class JoinRequest {
        @NotBlank
        private String code;
    }

    @Data
    public static class AddMemberRequest {
        @NotBlank
        private String email;
        /** MEMBER (default) / TRAINER / ADMIN. */
        private String role;
    }

    @Data
    public static class BannerRequest {
        private String text;
    }

    @Data
    public static class CheckinRequest {
        /** Optional focus for this visit, e.g. Push / Pull / Legs. */
        private String focus;
        /** Optional gym zone, e.g. Free weights / Racks / Cardio. */
        private String zone;
    }

    @Data
    public static class CreateEventRequest {
        @NotBlank
        private String title;
        private String body;
        private LocalDateTime startsAt;
    }
}
