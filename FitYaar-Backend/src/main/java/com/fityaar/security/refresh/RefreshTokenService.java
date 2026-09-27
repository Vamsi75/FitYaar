package com.fityaar.security.refresh;

import com.fityaar.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.UUID;

/** Persisted, single-use refresh tokens with rotation. */
@Service
@RequiredArgsConstructor
public class RefreshTokenService {

    private final RefreshTokenRepository repo;

    @Value("${app.jwt.refresh-expiration-ms}")
    private long refreshMs;

    @Transactional
    public String create(User user) {
        RefreshToken t = RefreshToken.builder()
                .token(UUID.randomUUID().toString())
                .user(user)
                .expiresAt(LocalDateTime.now().plus(Duration.ofMillis(refreshMs)))
                .revoked(false)
                .build();
        return repo.save(t).getToken();
    }

    /** Validates and rotates: the old token is revoked and a fresh one is issued. */
    @Transactional
    public Rotation rotate(String token) {
        RefreshToken t = repo.findByToken(token)
                .orElseThrow(() -> new BadCredentialsException("Invalid refresh token"));
        if (t.isRevoked() || t.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new BadCredentialsException("Refresh token expired or already used");
        }
        t.setRevoked(true);
        repo.save(t);
        return new Rotation(t.getUser(), create(t.getUser()));
    }

    public record Rotation(User user, String newRefreshToken) {
    }
}
