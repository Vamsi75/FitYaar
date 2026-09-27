package com.fityaar.audit.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fityaar.audit.entity.AuditLog;
import com.fityaar.user.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Map;

/**
 * Fail-soft audit logging. {@link #log} is NOT transactional and swallows every error, so a broken
 * audit write can never roll back or break the privileged action it was recording. The actual insert
 * runs in a fresh transaction via {@link AuditLogWriter}.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AuditService {

    private final AuditLogWriter writer;
    private final ObjectMapper objectMapper;

    // Canonical action names (kept as constants so the portal filter and call sites agree).
    public static final String CLAIM_SUPER = "CLAIM_SUPER";
    public static final String CREATE_GYM = "CREATE_GYM";
    public static final String ASSIGN_OWNER = "ASSIGN_OWNER";
    public static final String PLAN_CHANGED = "PLAN_CHANGED";
    public static final String USER_STATUS_CHANGED = "USER_STATUS_CHANGED";
    public static final String SUBSCRIPTION_GRANTED = "SUBSCRIPTION_GRANTED";
    public static final String PROMO_REDEEMED = "PROMO_REDEEMED";

    /** Record an action. Never throws. */
    public void log(User actor, String action, String resourceType, String resourceId,
                    Long gymId, Map<String, ?> metadata) {
        try {
            AuditLog entry = AuditLog.builder()
                    .actorId(actor != null ? actor.getId() : null)
                    .actorEmail(actor != null ? actor.getEmail() : null)
                    .action(action)
                    .resourceType(resourceType)
                    .resourceId(resourceId)
                    .gymId(gymId)
                    .metadata(metadata == null || metadata.isEmpty() ? null
                            : objectMapper.writeValueAsString(metadata))
                    .ip(currentIp())
                    .build();
            writer.write(entry);
        } catch (Exception e) {
            log.warn("Audit log failed for action {} (ignored): {}", action, e.getMessage());
        }
    }

    private String currentIp() {
        try {
            ServletRequestAttributes attrs =
                    (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            return attrs == null ? null : attrs.getRequest().getRemoteAddr();
        } catch (Exception e) {
            return null;
        }
    }
}
