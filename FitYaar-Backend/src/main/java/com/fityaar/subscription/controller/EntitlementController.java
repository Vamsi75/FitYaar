package com.fityaar.subscription.controller;

import com.fityaar.security.UserPrincipal;
import com.fityaar.subscription.dto.EntitlementView;
import com.fityaar.subscription.service.EntitlementService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Current user's Pro entitlement. */
@RestController
@RequestMapping("/api/me")
@RequiredArgsConstructor
public class EntitlementController {

    private final EntitlementService entitlementService;

    @GetMapping("/entitlements")
    public ResponseEntity<EntitlementView> entitlements(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(entitlementService.view(principal.getUser()));
    }
}
