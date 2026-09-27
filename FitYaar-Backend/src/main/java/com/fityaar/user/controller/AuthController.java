package com.fityaar.user.controller;

import com.fityaar.security.UserPrincipal;
import com.fityaar.security.jwt.JwtService;
import com.fityaar.security.refresh.RefreshTokenService;
import com.fityaar.user.dto.AuthResponse;
import com.fityaar.user.dto.GoogleRequest;
import com.fityaar.user.dto.LoginRequest;
import com.fityaar.user.dto.RefreshRequest;
import com.fityaar.user.dto.UserRequest;
import com.fityaar.user.entity.User;
import com.fityaar.user.service.GoogleAuthService;
import com.fityaar.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokenService;
    private final GoogleAuthService googleAuthService;
    private final AuthenticationManager authenticationManager;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody UserRequest request) {
        User user = userService.register(request);
        return ResponseEntity.ok(buildAuthResponse(new UserPrincipal(user), user));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        return ResponseEntity.ok(buildAuthResponse(principal, principal.getUser()));
    }

    /** Sign in with a Google ID token — verifies it and issues our JWT (creating the user if new). */
    @PostMapping("/google")
    public ResponseEntity<AuthResponse> google(@Valid @RequestBody GoogleRequest request) {
        User user = googleAuthService.verifyAndGetUser(request.getIdToken());
        return ResponseEntity.ok(buildAuthResponse(new UserPrincipal(user), user));
    }

    /** Exchange a valid refresh token for a new access token (rotates the refresh token). */
    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        RefreshTokenService.Rotation rotation = refreshTokenService.rotate(request.getRefreshToken());
        User user = rotation.user();
        return ResponseEntity.ok(AuthResponse.builder()
                .accessToken(jwtService.generateAccessToken(new UserPrincipal(user)))
                .refreshToken(rotation.newRefreshToken())
                .tokenType("Bearer")
                .expiresIn(jwtService.getAccessExpirationMs())
                .user(userService.toUserResponse(user))
                .build());
    }

    private AuthResponse buildAuthResponse(UserPrincipal principal, User user) {
        return AuthResponse.builder()
                .accessToken(jwtService.generateAccessToken(principal))
                .refreshToken(refreshTokenService.create(user))
                .tokenType("Bearer")
                .expiresIn(jwtService.getAccessExpirationMs())
                .user(userService.toUserResponse(user))
                .build();
    }
}
