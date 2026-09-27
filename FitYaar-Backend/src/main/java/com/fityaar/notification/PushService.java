package com.fityaar.notification;

import com.fityaar.notification.entity.DeviceToken;
import com.fityaar.notification.repository.DeviceTokenRepository;
import com.fityaar.user.entity.User;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.Collection;
import java.util.List;

/**
 * Sends FCM push. Fail-soft: when {@code app.fcm.enabled=false} or no credentials
 * are configured, sends are logged instead (mirrors the mail stub), so the app
 * runs fine before a Firebase project exists. Prunes dead tokens on send.
 */
@Service
@RequiredArgsConstructor
public class PushService {

    private static final Logger log = LoggerFactory.getLogger(PushService.class);

    private final DeviceTokenRepository tokenRepo;

    @Value("${app.fcm.enabled:false}")
    private boolean enabled;
    @Value("${app.fcm.service-account-json:}")
    private String serviceAccountJson;

    private FirebaseMessaging messaging; // null → disabled/log-only

    @PostConstruct
    void init() {
        if (!enabled || serviceAccountJson == null || serviceAccountJson.isBlank()) {
            log.info("FCM disabled (enabled={}, credentials {}). Push will be logged, not sent.",
                    enabled, (serviceAccountJson == null || serviceAccountJson.isBlank()) ? "absent" : "present");
            return;
        }
        try {
            final GoogleCredentials creds = GoogleCredentials.fromStream(
                    new ByteArrayInputStream(serviceAccountJson.getBytes(StandardCharsets.UTF_8)));
            final FirebaseApp app = FirebaseApp.getApps().isEmpty()
                    ? FirebaseApp.initializeApp(FirebaseOptions.builder().setCredentials(creds).build())
                    : FirebaseApp.getInstance();
            messaging = FirebaseMessaging.getInstance(app);
            log.info("FCM initialized — push enabled.");
        } catch (Exception e) {
            log.error("FCM init failed; push will be logged only. {}", e.getMessage());
        }
    }

    public void sendToUser(User user, String title, String body) {
        sendToUsers(List.of(user), title, body);
    }

    /** Push to every registered device of the given users. */
    public void sendToUsers(Collection<User> users, String title, String body) {
        if (users == null || users.isEmpty()) return;
        final List<String> tokens = tokenRepo.findByUserIn(users).stream()
                .map(DeviceToken::getToken).distinct().toList();
        sendToTokens(tokens, title, body);
    }

    private void sendToTokens(List<String> tokens, String title, String body) {
        if (tokens.isEmpty()) return;
        if (messaging == null) {
            log.info("[FCM disabled] would push '{}' to {} device(s).", title, tokens.size());
            return;
        }
        try {
            final MulticastMessage msg = MulticastMessage.builder()
                    .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                    .addAllTokens(tokens)
                    .build();
            final BatchResponse resp = messaging.sendEachForMulticast(msg);
            final List<SendResponse> responses = resp.getResponses();
            for (int i = 0; i < responses.size(); i++) {
                if (!responses.get(i).isSuccessful()) {
                    final FirebaseMessagingException ex = responses.get(i).getException();
                    final MessagingErrorCode code = ex != null ? ex.getMessagingErrorCode() : null;
                    if (code == MessagingErrorCode.UNREGISTERED || code == MessagingErrorCode.INVALID_ARGUMENT) {
                        tokenRepo.deleteByToken(tokens.get(i)); // drop dead token
                    }
                }
            }
            log.info("FCM push '{}': {}/{} delivered.", title, resp.getSuccessCount(), tokens.size());
        } catch (Exception e) {
            log.error("FCM send failed: {}", e.getMessage());
        }
    }
}
