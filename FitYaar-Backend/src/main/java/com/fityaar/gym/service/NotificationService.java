package com.fityaar.gym.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * Sends member-update notifications to the gym owner + the member.
 * Real SMTP is gated by {@code app.mail.enabled}; when off (default) it logs the
 * message so the flow works end-to-end without credentials.
 */
@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final boolean enabled;
    private final String from;
    private final ObjectProvider<JavaMailSender> mailProvider;

    public NotificationService(
            @Value("${app.mail.enabled:false}") boolean enabled,
            @Value("${app.mail.from:no-reply@fityaar.app}") String from,
            ObjectProvider<JavaMailSender> mailProvider) {
        this.enabled = enabled;
        this.from = from;
        this.mailProvider = mailProvider;
    }

    /** Notify the gym owner and the member that the member's gym record changed. */
    public void memberUpdated(String gymName, String ownerEmail, String memberEmail,
                              String memberName, String editorName, String summary) {
        final String subject = "FitYaar · %s membership updated".formatted(gymName);
        final String body = """
                Hi,

                %s's gym record at %s was updated by %s.

                %s

                — FitYaar""".formatted(memberName, gymName, editorName, summary);
        send(subject, body, ownerEmail, memberEmail);
    }

    private void send(String subject, String body, String... to) {
        final String[] recipients = java.util.Arrays.stream(to)
                .filter(s -> s != null && !s.isBlank()).toArray(String[]::new);
        if (recipients.length == 0) return;
        final JavaMailSender sender = enabled ? mailProvider.getIfAvailable() : null;
        if (sender == null) {
            log.info("[notify:{}] to={} subject='{}'\n{}",
                    enabled ? "mail-unavailable" : "disabled", String.join(",", recipients), subject, body);
            return;
        }
        try {
            final SimpleMailMessage msg = new SimpleMailMessage();
            msg.setFrom(from);
            msg.setTo(recipients);
            msg.setSubject(subject);
            msg.setText(body);
            sender.send(msg);
            log.info("[notify:sent] to={} subject='{}'", String.join(",", to), subject);
        } catch (Exception e) {
            log.warn("[notify:failed] {}", e.getMessage());
        }
    }
}
