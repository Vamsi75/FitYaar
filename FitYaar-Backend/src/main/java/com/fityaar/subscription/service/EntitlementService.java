package com.fityaar.subscription.service;

import com.fityaar.gym.entity.Gym;
import com.fityaar.gym.entity.GymMembership;
import com.fityaar.gym.repository.GymMembershipRepository;
import com.fityaar.subscription.dto.EntitlementView;
import com.fityaar.subscription.entity.Subscription;
import com.fityaar.subscription.repository.SubscriptionRepository;
import com.fityaar.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.Optional;

/**
 * Computes FitYaar Pro from a personal subscription OR a gym-sponsored plan. Repo-only
 * (no {@code UserService} dependency) to avoid a DI cycle, and read-only so it never mutates.
 * Runs per-request against fresh DB state, so grants/revocations take effect immediately.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class EntitlementService {

    private final SubscriptionRepository subscriptionRepo;
    private final GymMembershipRepository membershipRepo;

    public EntitlementView view(User user) {
        final LocalDateTime now = LocalDateTime.now();

        // 1) Personal subscription takes precedence. Prefer LIFETIME, then the latest-ending active row.
        Optional<Subscription> personal = subscriptionRepo
                .findByUserAndStatus(user, Subscription.Status.ACTIVE).stream()
                .filter(s -> s.getCurrentPeriodEnd() == null || s.getCurrentPeriodEnd().isAfter(now))
                .max(Comparator
                        .comparing((Subscription s) -> s.getCurrentPeriodEnd() == null) // LIFETIME wins
                        .thenComparing(Subscription::getCurrentPeriodEnd,
                                Comparator.nullsLast(Comparator.naturalOrder())));
        if (personal.isPresent()) {
            Subscription s = personal.get();
            return EntitlementView.builder()
                    .pro(true).plan(s.getPlan().name()).source(s.getSource().name())
                    .until(s.getCurrentPeriodEnd()).build();
        }

        // 2) Gym-sponsored: any ACTIVE membership in a gym whose plan is active.
        for (GymMembership m : membershipRepo.findByUser(user)) {
            if (m.getStatus() != GymMembership.Status.ACTIVE) continue;
            Gym g = m.getGym();
            if (g.getPlanStatus() == Gym.PlanStatus.ACTIVE
                    && (g.getPlanCurrentPeriodEnd() == null || g.getPlanCurrentPeriodEnd().isAfter(now))) {
                return EntitlementView.builder()
                        .pro(true).plan(g.getPlanTier()).source("GYM")
                        .until(g.getPlanCurrentPeriodEnd()).build();
            }
        }

        return EntitlementView.builder().pro(false).build();
    }

    public boolean pro(User user) {
        return view(user).isPro();
    }

    /** Guard for Pro-only endpoints → 403 via GlobalExceptionHandler. */
    public void requirePro(User user) {
        if (!pro(user)) {
            throw new AccessDeniedException("FitYaar Pro required");
        }
    }
}
