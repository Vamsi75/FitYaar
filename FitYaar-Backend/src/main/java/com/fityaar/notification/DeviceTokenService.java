package com.fityaar.notification;

import com.fityaar.notification.entity.DeviceToken;
import com.fityaar.notification.repository.DeviceTokenRepository;
import com.fityaar.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Registers / removes a device's FCM token, re-pointing a re-used token to the latest user. */
@Service
@RequiredArgsConstructor
public class DeviceTokenService {

    private final DeviceTokenRepository repo;

    @Transactional
    public void register(User user, String token, String platform) {
        if (token == null || token.isBlank()) return;
        final String t = token.trim();
        final DeviceToken dt = repo.findByToken(t).orElseGet(() -> DeviceToken.builder().token(t).build());
        dt.setUser(user);
        dt.setPlatform(platform);
        repo.save(dt);
    }

    @Transactional
    public void unregister(String token) {
        if (token != null && !token.isBlank()) repo.deleteByToken(token.trim());
    }
}
