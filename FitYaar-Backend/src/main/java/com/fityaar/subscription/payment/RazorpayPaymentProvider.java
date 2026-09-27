package com.fityaar.subscription.payment;

import com.razorpay.Order;
import com.razorpay.RazorpayClient;
import com.razorpay.RazorpayException;
import lombok.RequiredArgsConstructor;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "app.payment", name = "enabled", havingValue = "true")
public class RazorpayPaymentProvider implements PaymentProvider {

    @Value("${app.payment.razorpay-key-id:}")
    private String keyId;

    @Value("${app.payment.razorpay-key-secret:}")
    private String keySecret;

    @Override
    public PaymentOrder createOrder(long amountPaise, String currency, String receipt) {
        try {
            RazorpayClient client = new RazorpayClient(keyId, keySecret);
            JSONObject options = new JSONObject()
                    .put("amount", amountPaise)
                    .put("currency", currency)
                    .put("receipt", receipt);
            Order order = client.orders.create(options);
            return new PaymentOrder(order.get("id"), String.valueOf(order.get("amount")),
                    String.valueOf(order.get("currency")), String.valueOf(order.get("receipt")));
        } catch (RazorpayException e) {
            throw new IllegalStateException("Unable to create Razorpay order: " + e.getMessage(), e);
        }
    }

    @Override
    public boolean verifyPayment(String orderId, String paymentId, String signature) {
        if (orderId == null || paymentId == null || signature == null || signature.isBlank()) {
            return false;
        }
        String payload = orderId + "|" + paymentId;
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(keySecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] bytes = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(bytes.length * 2);
            for (byte b : bytes) {
                hex.append(String.format("%02x", b));
            }
            return constantTimeEquals(hex.toString(), signature.trim());
        } catch (Exception e) {
            return false;
        }
    }

    @Override
    public Map<String, Object> createPaymentLink(String gymName, String planName, long amountPaise,
                                                String currency, String description, String callbackUrl) {
        try {
            RazorpayClient client = new RazorpayClient(keyId, keySecret);
            JSONObject payload = new JSONObject()
                    .put("amount", amountPaise)
                    .put("currency", currency)
                    .put("description", description)
                    .put("callback_url", callbackUrl)
                    .put("customer", new JSONObject().put("name", gymName))
                    .put("notes", new JSONObject().put("plan", planName).put("gym", gymName));
            com.razorpay.PaymentLink link = client.paymentLink.create(payload);
            return Map.of(
                    "id", link.get("id"),
                    "short_url", link.get("short_url"),
                    "status", link.get("status"),
                    "amount", link.get("amount"),
                    "currency", link.get("currency"),
                    "description", link.get("description")
            );
        } catch (RazorpayException e) {
            throw new IllegalStateException("Unable to create Razorpay payment link: " + e.getMessage(), e);
        }
    }

    private boolean constantTimeEquals(String a, String b) {
        if (a.length() != b.length()) {
            return false;
        }
        int diff = 0;
        for (int i = 0; i < a.length(); i++) {
            diff |= a.charAt(i) ^ b.charAt(i);
        }
        return diff == 0;
    }
}
