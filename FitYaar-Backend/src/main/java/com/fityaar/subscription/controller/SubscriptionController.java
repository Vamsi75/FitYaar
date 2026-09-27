package com.fityaar.subscription.controller;

import com.fityaar.audit.service.AuditService;
import com.fityaar.security.UserPrincipal;
import com.fityaar.subscription.dto.EntitlementView;
import com.fityaar.subscription.dto.SubscriptionRequests.GrantRequest;
import com.fityaar.subscription.dto.SubscriptionRequests.RedeemRequest;
import com.fityaar.subscription.entity.Subscription;
import com.fityaar.subscription.service.EntitlementService;
import com.fityaar.subscription.service.SubscriptionService;
import com.fityaar.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/subscriptions")
@RequiredArgsConstructor
public class SubscriptionController {

    private final SubscriptionService subscriptionService;
    private final EntitlementService entitlementService;
    private final AuditService audit;

    /** Super-admin grants Pro to a user (comp / influencer / support). */
    @PostMapping("/grant")
    public ResponseEntity<Map<String, Object>> grant(@Valid @RequestBody GrantRequest req,
                                                     @AuthenticationPrincipal UserPrincipal principal) {
        if (principal.getUser().getRole() != User.Role.ADMIN) {
            throw new AccessDeniedException("Super admin only");
        }
        Subscription sub = subscriptionService.grantManual(req.getEmail(), SubscriptionService.parsePlan(req.getPlan()));
        audit.log(principal.getUser(), AuditService.SUBSCRIPTION_GRANTED, "USER",
                sub.getUser().getEmail(), null, Map.of("plan", sub.getPlan().name()));
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("userId", sub.getUser().getId());
        body.put("plan", sub.getPlan().name());
        body.put("until", sub.getCurrentPeriodEnd() == null ? "never" : sub.getCurrentPeriodEnd().toString());
        return ResponseEntity.ok(body);
    }

    /** Any authenticated user redeems a promo code → Pro. Returns the refreshed entitlement. */
    @PostMapping("/redeem")
    public ResponseEntity<EntitlementView> redeem(@Valid @RequestBody RedeemRequest req,
                                                  @AuthenticationPrincipal UserPrincipal principal) {
        subscriptionService.redeem(principal.getUser(), req.getCode());
        audit.log(principal.getUser(), AuditService.PROMO_REDEEMED, "USER",
                principal.getUser().getEmail(), null, null);
        return ResponseEntity.ok(entitlementService.view(principal.getUser()));
    }
}
