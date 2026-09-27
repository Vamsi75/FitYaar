package com.fityaar.audit.repository;

import com.fityaar.audit.entity.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {

    /** Filtered, paged audit feed. Any null filter is ignored. */
    @Query("SELECT a FROM AuditLog a WHERE " +
            "(:gymId IS NULL OR a.gymId = :gymId) " +
            "AND (:actorId IS NULL OR a.actorId = :actorId) " +
            "AND (:action IS NULL OR a.action = :action)")
    Page<AuditLog> search(@Param("gymId") Long gymId,
                          @Param("actorId") Long actorId,
                          @Param("action") String action,
                          Pageable pageable);
}
