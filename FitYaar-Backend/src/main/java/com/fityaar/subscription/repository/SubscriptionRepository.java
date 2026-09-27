package com.fityaar.subscription.repository;

import com.fityaar.subscription.entity.Subscription;
import com.fityaar.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SubscriptionRepository extends JpaRepository<Subscription, Long> {

    List<Subscription> findByUserAndStatus(User user, Subscription.Status status);

    /** Webhook idempotency (Phase 2) — dedupe on the provider's order/subscription id. */
    Optional<Subscription> findFirstByProviderRef(String providerRef);

    // --- Super-admin console (subscriptions list + monetization metrics) ---

    List<Subscription> findByStatus(Subscription.Status status);

    /**
     * Filtered, paged subscriptions for the management portal. {@code pattern} is a pre-lowercased
     * {@code %...%} LIKE pattern (null = no text filter) — see UserRepository.adminSearch for why.
     */
    @Query("SELECT s FROM Subscription s JOIN s.user u LEFT JOIN u.profile p WHERE " +
            "(:status IS NULL OR s.status = :status) " +
            "AND (:source IS NULL OR s.source = :source) " +
            "AND (:plan IS NULL OR s.plan = :plan) " +
            "AND (:pattern IS NULL OR LOWER(u.email) LIKE :pattern " +
            "   OR LOWER(p.displayName) LIKE :pattern)")
    Page<Subscription> adminSearch(@Param("status") Subscription.Status status,
                                   @Param("source") Subscription.Source source,
                                   @Param("plan") Subscription.Plan plan,
                                   @Param("pattern") String pattern,
                                   Pageable pageable);
}
