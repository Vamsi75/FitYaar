package com.fityaar.audit.service;

import com.fityaar.audit.entity.AuditLog;
import com.fityaar.audit.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Persists an audit line in its OWN transaction so it commits/rolls back independently of the
 * business action being logged. Kept separate from {@link AuditService} so the try/catch there
 * sits OUTSIDE this transaction boundary (a rollback here can't surface as a caller error).
 */
@Service
@RequiredArgsConstructor
public class AuditLogWriter {

    private final AuditLogRepository repo;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void write(AuditLog entry) {
        repo.save(entry);
    }
}
