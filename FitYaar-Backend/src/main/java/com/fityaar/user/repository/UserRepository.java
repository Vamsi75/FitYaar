package com.fityaar.user.repository;

import com.fityaar.user.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);

    @Query("SELECT u FROM User u LEFT JOIN u.profile p " +
            "WHERE u.id <> :selfId AND (" +
            "LOWER(p.displayName) LIKE LOWER(CONCAT('%', :q, '%')) " +
            "OR LOWER(u.email) LIKE LOWER(CONCAT('%', :q, '%')))")
    List<User> searchUsers(String q, Long selfId);

    // --- Super-admin console (metrics + user management) ---

    long countByStatus(User.Status status);

    long countByCreatedAtAfter(LocalDateTime after);

    /**
     * Filtered, paged user list for the management portal. {@code pattern} is a pre-lowercased
     * {@code %...%} LIKE pattern (null = no text filter); comparing the param directly avoids the
     * Postgres "lower(bytea)" untyped-null error that wrapping a nullable param in LOWER() triggers.
     */
    @Query("SELECT u FROM User u LEFT JOIN u.profile p WHERE " +
            "(:pattern IS NULL OR LOWER(u.email) LIKE :pattern " +
            "   OR LOWER(p.displayName) LIKE :pattern) " +
            "AND (:status IS NULL OR u.status = :status) " +
            "AND (:role IS NULL OR u.role = :role)")
    Page<User> adminSearch(@Param("pattern") String pattern,
                           @Param("status") User.Status status,
                           @Param("role") User.Role role,
                           Pageable pageable);

    /** Just the creation timestamps in range, for cheap signup time-series bucketing. */
    @Query("SELECT u.createdAt FROM User u WHERE u.createdAt >= :after")
    List<LocalDateTime> createdAtSince(@Param("after") LocalDateTime after);
}
