package com.fityaar.subscription.payment;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PaymentServiceTest {

    @Test
    void verifiesRazorpaySignatureUsingOrderAndPaymentIds() {
        String payload = "order_123|pay_456";
        String secret = "test-secret";
        String signature = PaymentSignature.sign(payload, secret);

        assertTrue(PaymentSignature.valid(payload.getBytes(), signature, secret));
        assertFalse(PaymentSignature.valid(payload.getBytes(), "bad-signature", secret));
    }
}
