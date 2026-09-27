package com.fityaar.subscription.payment;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Razorpay webhook. Signature validation happens in the backend before any business logic is run.
 */
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "app.payment", name = "enabled", havingValue = "true")
public class RazorpayWebhookController {

    private static final Logger log = LoggerFactory.getLogger(RazorpayWebhookController.class);

    private final PaymentService paymentService;
    private final ObjectMapper objectMapper;

    @PostMapping({"/payments/webhook", "/payments/razorpay/webhook"})
    public ResponseEntity<Void> handle(@RequestBody byte[] rawBody,
                                       @RequestHeader(value = "X-Razorpay-Signature", required = false) String signature) {
        if (!PaymentSignature.valid(rawBody, signature, paymentService.webhookSecret())) {
            log.warn("Rejected Razorpay webhook: bad signature");
            return ResponseEntity.badRequest().build();
        }
        try {
            Map<String, Object> event = objectMapper.readValue(rawBody, new TypeReference<>() {});
            Object rawEventType = event.get("event");
            String eventType = rawEventType instanceof String s ? s : "";
            if (!eventType.isBlank()) {
                log.info("Razorpay webhook accepted: {}", eventType);
            }
        } catch (Exception e) {
            log.warn("Razorpay webhook payload was not parseable: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok().build();
    }
}
