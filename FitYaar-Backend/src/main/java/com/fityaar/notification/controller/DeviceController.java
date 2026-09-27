package com.fityaar.notification.controller;

import com.fityaar.notification.DeviceTokenService;
import com.fityaar.security.UserPrincipal;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/** Register / unregister this device's FCM token (authenticated). */
@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
public class DeviceController {

    private final DeviceTokenService service;

    @PostMapping("/token")
    public ResponseEntity<Void> register(@RequestBody DeviceTokenRequest req,
                                         @AuthenticationPrincipal UserPrincipal principal) {
        service.register(principal.getUser(), req.getToken(), req.getPlatform());
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/token")
    public ResponseEntity<Void> unregister(@RequestBody DeviceTokenRequest req,
                                           @AuthenticationPrincipal UserPrincipal principal) {
        service.unregister(req.getToken());
        return ResponseEntity.noContent().build();
    }

    @Data
    public static class DeviceTokenRequest {
        private String token;
        private String platform;
    }
}
