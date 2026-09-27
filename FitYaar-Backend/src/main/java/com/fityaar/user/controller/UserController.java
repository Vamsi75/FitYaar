package com.fityaar.user.controller;

import com.fityaar.security.UserPrincipal;
import com.fityaar.user.dto.EmailUpdateRequest;
import com.fityaar.user.dto.PasswordChangeRequest;
import com.fityaar.user.dto.ProfileRequest;
import com.fityaar.user.dto.ProfileResponse;
import com.fityaar.user.entity.User;
import com.fityaar.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/profile")
    public ResponseEntity<ProfileResponse> getProfile(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(userService.getProfile(principal.getUser()));
    }

    @PutMapping("/profile")
    public ResponseEntity<ProfileResponse> updateProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody ProfileRequest request) {
        User user = userService.findById(principal.getId());
        return ResponseEntity.ok(userService.updateProfile(user, request));
    }

    @PostMapping("/change-password")
    public ResponseEntity<Void> changePassword(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody PasswordChangeRequest request) {
        userService.changePassword(principal.getUser(), request.getCurrentPassword(), request.getNewPassword());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/update-email")
    public ResponseEntity<Void> updateEmail(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody EmailUpdateRequest request) {
        userService.updateEmail(principal.getUser(), request.getNewEmail(), request.getPassword());
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping
    public ResponseEntity<Void> deleteAccount(@AuthenticationPrincipal UserPrincipal principal) {
        userService.deleteAccount(principal.getUser());
        return ResponseEntity.noContent().build();
    }
}
