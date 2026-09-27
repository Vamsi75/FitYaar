package com.fityaar.subscription.payment;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

/**
 * Central payment orchestration. Business logic stays provider-agnostic; implementations
 * are swapped behind {@link PaymentProvider}.
 */
@Service
@RequiredArgsConstructor
public class PaymentService {

    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);

    private final PaymentProvider paymentProvider;

    @Value("${app.payment.enabled:false}")
    private boolean enabled;
    @Value("${app.payment.razorpay-key-id:}")
    private String keyId;
    @Value("${app.payment.razorpay-key-secret:}")
    private String keySecret;
    @Value("${app.payment.webhook-secret:}")
    private String webhookSecret;

    @PostConstruct
    void init() {
        if (!isEnabled()) {
            log.info("Payment disabled (enabled={}, keys {}). Checkout will be stubbed.",
                    enabled, (keyId == null || keyId.isBlank()) ? "absent" : "present");
        } else {
            log.info("Payment enabled — Razorpay checkout active.");
        }
    }

    public boolean isEnabled() {
        return enabled && paymentProvider != null && keyId != null && !keyId.isBlank() && keySecret != null && !keySecret.isBlank();
    }

    public String webhookSecret() {
        return webhookSecret;
    }

    public Map<String, Object> createOrder(Long userId, String plan) {
        if (!isEnabled()) {
            throw new IllegalStateException("Payments are not enabled yet");
        }
        String normalized = plan == null ? "MONTHLY" : plan.trim().toUpperCase(Locale.ROOT);
        long amountPaise = switch (normalized) {
            case "MONTHLY" -> 19900L;
            case "YEARLY" -> 149900L;
            case "LIFETIME" -> 499900L;
            default -> 19900L;
        };
        String receipt = "fityaar-" + userId + "-" + Instant.now().toEpochMilli();
        PaymentProvider.PaymentOrder order = paymentProvider.createOrder(amountPaise, "INR", receipt);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("key", keyId);
        body.put("orderId", order.id());
        body.put("amount", order.amount());
        body.put("currency", order.currency());
        body.put("receipt", order.receipt());
        body.put("plan", normalized);
        return body;
    }

    public boolean verifyPayment(String orderId, String paymentId, String signature) {
        return paymentProvider.verifyPayment(orderId, paymentId, signature);
    }

    public Map<String, Object> createPaymentLink(String gymName, String planName, long amountPaise,
                                                String description, String callbackUrl) {
        if (!isEnabled()) {
            throw new IllegalStateException("Payments are not enabled yet");
        }
        return paymentProvider.createPaymentLink(gymName, planName, amountPaise, "INR", description, callbackUrl);
    }
}
