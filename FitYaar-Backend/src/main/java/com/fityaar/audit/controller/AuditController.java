package com.fityaar.audit.controller;

import com.fityaar.audit.entity.AuditLog;
import com.fityaar.audit.repository.AuditLogRepository;
import com.fityaar.security.AuthorizationService;
import com.fityaar.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/** Super-admin audit feed (read-only). */
@RestController
@RequestMapping("/api/admin/audit")
@RequiredArgsConstructor
public class AuditController {

    private final AuditLogRepository repo;
    private final AuthorizationService authz;

    @GetMapping
    public ResponseEntity<Page<AuditLog>> list(@RequestParam(required = false) Long gymId,
                                               @RequestParam(required = false) Long actorId,
                                               @RequestParam(required = false) String action,
                                               @RequestParam(defaultValue = "0") int page,
                                               @RequestParam(defaultValue = "50") int size,
                                               @AuthenticationPrincipal UserPrincipal principal) {
        authz.requireSuper(principal.getUser());
        String act = action == null || action.isBlank() ? null : action.trim();
        PageRequest pr = PageRequest.of(page, Math.min(size, 200), Sort.by(Sort.Direction.DESC, "createdAt"));
        return ResponseEntity.ok(repo.search(gymId, actorId, act, pr));
    }
}
