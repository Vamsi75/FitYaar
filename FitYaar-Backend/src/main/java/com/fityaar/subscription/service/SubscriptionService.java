package com.fityaar.subscription.service;

import com.fityaar.exception.ResourceNotFoundException;
import com.fityaar.subscription.entity.Subscription;
import com.fityaar.subscription.repository.SubscriptionRepository;
import com.fityaar.user.entity.User;
import com.fityaar.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Locale;

/** Write side for personal subscriptions: super-admin grants, promo redemption, and provider (Razorpay) records. */
@Service
@RequiredArgsConstructor
public class SubscriptionService {

    private final SubscriptionRepository subscriptionRepo;
    private final UserRepository userRepo;

    /** Comma-separated promo codes that grant 1 year of Pro. Empty = promos disabled. */
    @Value("${app.promo.codes:}")
    private String promoCodes;

    @Transactional
    public Subscription grantManual(String email, Subscription.Plan plan) {
        User user = userRepo.findByEmail(email.trim())
                .orElseThrow(() -> new ResourceNotFoundException("No user with email " + email));
        return save(user, Subscription.Source.MANUAL, plan, null);
    }

    @Transactional
    public Subscription redeem(User user, String code) {
        String c = code == null ? "" : code.trim();
        boolean valid = !c.isEmpty() && Arrays.stream(promoCodes.split(","))
                .map(String::trim).filter(s -> !s.isEmpty())
                .anyMatch(s -> s.equalsIgnoreCase(c));
        if (!valid) throw new IllegalArgumentException("Invalid or expired promo code");
        return save(user, Subscription.Source.PROMO, Subscription.Plan.YEARLY, null);
    }

    /** Idempotent record from a payment-provider webhook (Phase 2). */
    @Transactional
    public Subscription recordFromProvider(String email, Subscription.Plan plan, String providerRef) {
        if (providerRef != null) {
            var existing = subscriptionRepo.findFirstByProviderRef(providerRef);
            if (existing.isPresent()) return existing.get();
        }
        User user = userRepo.findByEmail(email.trim())
                .orElseThrow(() -> new ResourceNotFoundException("No user with email " + email));
        return save(user, Subscription.Source.RAZORPAY, plan, providerRef);
    }

    private Subscription save(User user, Subscription.Source source, Subscription.Plan plan, String providerRef) {
        LocalDateTime end = switch (plan) {
            case MONTHLY -> LocalDateTime.now().plusMonths(1);
            case YEARLY -> LocalDateTime.now().plusYears(1);
            case LIFETIME -> null;
        };
        Subscription s = Subscription.builder()
                .user(user).source(source).plan(plan)
                .status(Subscription.Status.ACTIVE)
                .currentPeriodEnd(end).providerRef(providerRef)
                .build();
        return subscriptionRepo.save(s);
    }

    public static Subscription.Plan parsePlan(String plan) {
        return Subscription.Plan.valueOf(plan.trim().toUpperCase(Locale.ROOT));
    }
}
