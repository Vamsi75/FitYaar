package com.fityaar.subscription.payment;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.Map;

/** Fallback provider for development/testing when live payments are disabled. */
@Component
@ConditionalOnProperty(prefix = "app.payment", name = "enabled", havingValue = "false", matchIfMissing = true)
public class StubPaymentProvider implements PaymentProvider {

    @Override
    public PaymentOrder createOrder(long amountPaise, String currency, String receipt) {
        return new PaymentOrder("stub_order_" + System.currentTimeMillis(), String.valueOf(amountPaise), currency, receipt);
    }

    @Override
    public boolean verifyPayment(String orderId, String paymentId, String signature) {
        // In stub mode, any signature starting with 'stub_' is considered valid
        return signature != null && signature.startsWith("stub_");
    }

    @Override
    public Map<String, Object> createPaymentLink(String gymName, String planName, long amountPaise,
                                                String currency, String description, String callbackUrl) {
        return Map.of(
                "id", "stub_link_" + System.currentTimeMillis(),
                "short_url", "https://fityaar.app/stub-pay",
                "status", "created",
                "amount", amountPaise,
                "currency", currency,
                "description", description
        );
    }
}
