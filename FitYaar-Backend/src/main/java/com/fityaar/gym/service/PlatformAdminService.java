package com.fityaar.gym.service;

import com.fityaar.audit.service.AuditService;
import com.fityaar.exception.ResourceNotFoundException;
import com.fityaar.gym.dto.AdminRequests.GymBillingRequest;
import com.fityaar.gym.dto.GymAdminDto;
import com.fityaar.gym.dto.GymSeatUtilization;
import com.fityaar.gym.dto.MembershipView;
import com.fityaar.gym.entity.Gym;
import com.fityaar.gym.entity.GymMembership;
import com.fityaar.gym.entity.GymMembership.Role;
import com.fityaar.gym.entity.GymMembership.Status;
import com.fityaar.gym.repository.GymMembershipRepository;
import com.fityaar.gym.repository.GymRepository;
import com.fityaar.user.entity.User;
import com.fityaar.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

/** Platform-level (super-admin) gym management. Super-admin = User with role ADMIN. */
@Service
@RequiredArgsConstructor
public class PlatformAdminService {

    private final UserRepository userRepo;
    private final GymRepository gymRepo;
    private final GymMembershipRepository membershipRepo;
    private final AuditService audit;

    @Value("${app.super-admin-code:LETMEIN-SUPER}")
    private String superAdminCode;

    /** One-time bootstrap: promote the current user to platform super-admin. */
    @Transactional
    public void claim(User user, String code) {
        if (code == null || !superAdminCode.equals(code.trim())) {
            throw new AccessDeniedException("Invalid super-admin code");
        }
        user.setRole(User.Role.ADMIN);
        userRepo.save(user);
        audit.log(user, AuditService.CLAIM_SUPER, "USER", user.getEmail(), null, null);
    }

    public List<GymAdminDto> listGyms(User admin) {
        requireSuper(admin);
        return gymRepo.findAll().stream().map(this::toDto).toList();
    }

    @Transactional
    public GymAdminDto createGym(User admin, String name, Integer capacity, String joinCode, String ownerCode) {
        requireSuper(admin);
        if (gymRepo.findByJoinCode(joinCode).isPresent()
                || gymRepo.findByOwnerCode(ownerCode).isPresent()) {
            throw new IllegalStateException("That join or owner code is already in use");
        }
        Gym g = Gym.builder()
                .name(name).capacity(capacity).joinCode(joinCode).ownerCode(ownerCode).build();
        g = gymRepo.save(g);
        audit.log(admin, AuditService.CREATE_GYM, "GYM", String.valueOf(g.getId()), g.getId(),
                Map.of("name", g.getName()));
        return toDto(g);
    }

    /** Super-admin assigns a gym OWNER (only super-admin may mint owners). */
    @Transactional
    public MembershipView assignOwner(User admin, Long gymId, String email) {
        requireSuper(admin);
        Gym g = gymRepo.findById(gymId)
                .orElseThrow(() -> new ResourceNotFoundException("Gym not found"));
        User u = userRepo.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("No user with email " + email));
        GymMembership m = membershipRepo.findByUserAndGym(u, g)
                .orElse(GymMembership.builder().user(u).gym(g).build());
        m.setRole(Role.OWNER);
        m.setStatus(Status.ACTIVE);
        membershipRepo.save(m);
        audit.log(admin, AuditService.ASSIGN_OWNER, "GYM", String.valueOf(g.getId()), g.getId(),
                Map.of("email", u.getEmail()));
        String name = u.getProfile() != null ? u.getProfile().getDisplayName() : null;
        return MembershipView.builder()
                .membershipId(m.getId()).userId(u.getId()).displayName(name)
                .email(u.getEmail()).role(m.getRole().name()).status(m.getStatus().name())
                .gymId(g.getId()).gymName(g.getName()).build();
    }

    /** Super-admin account lifecycle. */
    @Transactional
    public void setUserStatus(User admin, String email, User.Status status) {
        requireSuper(admin);
        User u = userRepo.findByEmail(email.trim())
                .orElseThrow(() -> new ResourceNotFoundException("No user with email " + email));
        u.setStatus(status);
        userRepo.save(u);
        audit.log(admin, AuditService.USER_STATUS_CHANGED, "USER", u.getEmail(), null,
                Map.of("status", status.name()));
    }

    /** Set/clear a gym's B2B plan. An ACTIVE, unexpired plan grants Pro to all ACTIVE members. */
    @Transactional
    public GymAdminDto setGymPlan(User admin, Long gymId, GymBillingRequest req) {
        requireSuper(admin);
        Gym g = gymRepo.findById(gymId)
                .orElseThrow(() -> new ResourceNotFoundException("Gym not found"));
        g.setPlanTier(req.getPlanTier());
        g.setPlanStatus(req.getPlanStatus() == null || req.getPlanStatus().isBlank()
                ? null : Gym.PlanStatus.valueOf(req.getPlanStatus().trim().toUpperCase()));
        g.setPlanCurrentPeriodEnd(req.getPlanCurrentPeriodEnd());
        g.setPaidSeats(req.getPaidSeats());
        g = gymRepo.save(g);
        audit.log(admin, AuditService.PLAN_CHANGED, "GYM", String.valueOf(g.getId()), g.getId(),
                Map.of("planTier", String.valueOf(g.getPlanTier()),
                        "planStatus", String.valueOf(g.getPlanStatus())));
        return toDto(g);
    }

    /** All memberships in a gym (any role/status) for the super-admin gym detail view. */
    public List<MembershipView> listGymMembers(User admin, Long gymId) {
        requireSuper(admin);
        Gym g = gymRepo.findById(gymId)
                .orElseThrow(() -> new ResourceNotFoundException("Gym not found"));
        return membershipRepo.findByGym(g).stream()
                .map(m -> {
                    User u = m.getUser();
                    String name = u.getProfile() != null ? u.getProfile().getDisplayName() : null;
                    return MembershipView.builder()
                            .membershipId(m.getId()).userId(u.getId()).displayName(name)
                            .email(u.getEmail()).role(m.getRole().name()).status(m.getStatus().name())
                            .joinedAt(m.getCreatedAt() == null ? null : m.getCreatedAt().toLocalDate())
                            .gymId(g.getId()).gymName(g.getName())
                            .build();
                })
                .toList();
    }

    /** Active-member count vs paid seats (advisory over-cap flag). */
    public GymSeatUtilization seatUtilization(User admin, Long gymId) {
        requireSuper(admin);
        Gym g = gymRepo.findById(gymId)
                .orElseThrow(() -> new ResourceNotFoundException("Gym not found"));
        long active = membershipRepo.findByGymAndStatus(g, Status.ACTIVE).size();
        Integer seats = g.getPaidSeats();
        return GymSeatUtilization.builder()
                .gymId(g.getId()).name(g.getName())
                .planTier(g.getPlanTier())
                .planStatus(g.getPlanStatus() == null ? null : g.getPlanStatus().name())
                .planCurrentPeriodEnd(g.getPlanCurrentPeriodEnd())
                .paidSeats(seats).activeMembers(active)
                .overCap(seats != null && active > seats)
                .build();
    }

    private void requireSuper(User user) {
        if (user.getRole() != User.Role.ADMIN) {
            throw new AccessDeniedException("Super admin only");
        }
    }

    private GymAdminDto toDto(Gym g) {
        return GymAdminDto.builder()
                .id(g.getId()).name(g.getName()).joinCode(g.getJoinCode())
                .ownerCode(g.getOwnerCode()).capacity(g.getCapacity())
                .planTier(g.getPlanTier())
                .planStatus(g.getPlanStatus() == null ? null : g.getPlanStatus().name())
                .planCurrentPeriodEnd(g.getPlanCurrentPeriodEnd())
                .paidSeats(g.getPaidSeats())
                .build();
    }
}
