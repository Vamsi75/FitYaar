package com.fityaar.admin.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/** One row in the management portal's users table (cheap — no per-row entitlement lookup). */
@Data
@Builder
public class AdminUserRow {
    private Long id;
    private String email;
    private String displayName;
    private String role;
    private String status;
    private LocalDateTime createdAt;
}
