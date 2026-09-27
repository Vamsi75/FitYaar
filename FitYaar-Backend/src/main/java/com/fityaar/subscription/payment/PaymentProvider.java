package com.fityaar.subscription.payment;

import java.util.Map;

public interface PaymentProvider {

    PaymentOrder createOrder(long amountPaise, String currency, String receipt);

    boolean verifyPayment(String orderId, String paymentId, String signature);

    default Map<String, Object> createPaymentLink(String gymName, String planName, long amountPaise,
                                                 String currency, String description, String callbackUrl) {
        throw new UnsupportedOperationException("Payment link creation is not supported by this provider");
    }

    record PaymentOrder(String id, String amount, String currency, String receipt) {}
}
