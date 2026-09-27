package com.fityaar.gym.controller;

import com.fityaar.gym.dto.AdminRequests.AssignAdminRequest;
import com.fityaar.gym.dto.AdminRequests.ClaimRequest;
import com.fityaar.gym.dto.AdminRequests.CreateGymRequest;
import com.fityaar.gym.dto.AdminRequests.GymBillingRequest;
import com.fityaar.gym.dto.AdminRequests.UserEmailRequest;
import com.fityaar.gym.dto.GymAdminDto;
import com.fityaar.gym.dto.GymSeatUtilization;
import com.fityaar.gym.dto.MembershipView;
import com.fityaar.gym.service.PlatformAdminService;
import com.fityaar.security.UserPrincipal;
import com.fityaar.user.entity.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class PlatformAdminController {

    private final PlatformAdminService service;

    @PostMapping("/claim")
    public ResponseEntity<Map<String, String>> claim(@Valid @RequestBody ClaimRequest request,
                                                     @AuthenticationPrincipal UserPrincipal principal) {
        service.claim(principal.getUser(), request.getCode());
        return ResponseEntity.ok(Map.of("role", "ADMIN"));
    }

    @GetMapping("/gyms")
    public ResponseEntity<List<GymAdminDto>> listGyms(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(service.listGyms(principal.getUser()));
    }

    @PostMapping("/gyms")
    public ResponseEntity<GymAdminDto> createGym(@Valid @RequestBody CreateGymRequest request,
                                                 @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(service.createGym(principal.getUser(),
                request.getName(), request.getCapacity(), request.getJoinCode(), request.getOwnerCode()));
    }

    @PostMapping("/gyms/{id}/admins")
    public ResponseEntity<MembershipView> assignOwner(@PathVariable Long id,
                                                      @Valid @RequestBody AssignAdminRequest request,
                                                      @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(service.assignOwner(principal.getUser(), id, request.getEmail().trim()));
    }

    @PostMapping("/users/suspend")
    public ResponseEntity<Void> suspendUser(@Valid @RequestBody UserEmailRequest req,
                                            @AuthenticationPrincipal UserPrincipal principal) {
        service.setUserStatus(principal.getUser(), req.getEmail(), User.Status.SUSPENDED);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/users/reactivate")
    public ResponseEntity<Void> reactivateUser(@Valid @RequestBody UserEmailRequest req,
                                               @AuthenticationPrincipal UserPrincipal principal) {
        service.setUserStatus(principal.getUser(), req.getEmail(), User.Status.ACTIVE);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/users/deactivate")
    public ResponseEntity<Void> deactivateUser(@Valid @RequestBody UserEmailRequest req,
                                               @AuthenticationPrincipal UserPrincipal principal) {
        service.setUserStatus(principal.getUser(), req.getEmail(), User.Status.DEACTIVATED);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/gyms/{id}/plan")
    public ResponseEntity<GymAdminDto> setGymPlan(@PathVariable Long id,
                                                  @RequestBody GymBillingRequest request,
                                                  @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(service.setGymPlan(principal.getUser(), id, request));
    }

    @GetMapping("/gyms/{id}/seats")
    public ResponseEntity<GymSeatUtilization> seats(@PathVariable Long id,
                                                    @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(service.seatUtilization(principal.getUser(), id));
    }
}
