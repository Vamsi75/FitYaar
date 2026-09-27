package com.fityaar.admin.controller;

import com.fityaar.admin.dto.AdminSubscriptionRow;
import com.fityaar.admin.dto.AdminUserDetail;
import com.fityaar.admin.dto.AdminUserRow;
import com.fityaar.admin.dto.PlatformOverview;
import com.fityaar.admin.dto.TimeSeriesPoint;
import com.fityaar.admin.service.AdminConsoleService;
import com.fityaar.gym.dto.MembershipView;
import com.fityaar.gym.service.PlatformAdminService;
import com.fityaar.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Super-admin management-portal read APIs (metrics, users, subscriptions, gym members).
 * Shares the {@code /api/admin} base with {@link com.fityaar.gym.controller.PlatformAdminController}
 * (which owns the write actions); paths do not overlap. Every method is super-admin guarded in the service.
 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminConsoleController {

    private final AdminConsoleService console;
    private final PlatformAdminService platformAdmin;

    @GetMapping("/metrics/overview")
    public ResponseEntity<PlatformOverview> overview(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(console.overview(principal.getUser()));
    }

    @GetMapping("/metrics/timeseries")
    public ResponseEntity<List<TimeSeriesPoint>> timeseries(
            @RequestParam(name = "metric", defaultValue = "signups") String metric,
            @RequestParam(name = "days", defaultValue = "30") int days,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(console.timeseries(principal.getUser(), metric, days));
    }

    @GetMapping("/users")
    public ResponseEntity<Page<AdminUserRow>> users(
            @RequestParam(name = "q", required = false) String q,
            @RequestParam(name = "role", required = false) String role,
            @RequestParam(name = "status", required = false) String status,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "25") int size,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(console.users(principal.getUser(), q, role, status, page, size));
    }

    @GetMapping("/users/{id}")
    public ResponseEntity<AdminUserDetail> userDetail(@PathVariable(name = "id") Long id,
                                                      @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(console.userDetail(principal.getUser(), id));
    }

    @GetMapping("/subscriptions")
    public ResponseEntity<Page<AdminSubscriptionRow>> subscriptions(
            @RequestParam(name = "status", required = false) String status,
            @RequestParam(name = "source", required = false) String source,
            @RequestParam(name = "plan", required = false) String plan,
            @RequestParam(name = "q", required = false) String q,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "25") int size,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(console.subscriptions(principal.getUser(), status, source, plan, q, page, size));
    }

    @GetMapping("/gyms/{id}/members")
    public ResponseEntity<List<MembershipView>> gymMembers(@PathVariable(name = "id") Long id,
                                                           @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(platformAdmin.listGymMembers(principal.getUser(), id));
    }
}
