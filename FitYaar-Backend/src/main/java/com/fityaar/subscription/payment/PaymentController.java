package com.fityaar.subscription.payment;

import com.fityaar.security.UserPrincipal;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    @PostMapping("/order")
    public ResponseEntity<Map<String, Object>> order(@Valid @RequestBody OrderRequest req,
                                                    @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(paymentService.createOrder(principal.getUser().getId(), req.getPlan()));
    }

    @PostMapping("/verify")
    public ResponseEntity<Map<String, Object>> verify(@RequestBody VerifyRequest req) {
        boolean ok = paymentService.verifyPayment(req.getOrderId(), req.getPaymentId(), req.getSignature());
        return ResponseEntity.ok(Map.of(
                "verified", ok,
                "orderId", req.getOrderId(),
                "paymentId", req.getPaymentId(),
                "signature", req.getSignature() != null ? "present" : "missing"
        ));
    }

    @Data
    public static class OrderRequest {
        @NotBlank
        private String plan;
    }

    @Data
    public static class VerifyRequest {
        private String orderId;
        private String paymentId;
        private String signature;
    }
}
