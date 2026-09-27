package com.fityaar.security;

import com.fityaar.exception.ResourceNotFoundException;
import com.fityaar.gym.entity.Gym;
import com.fityaar.gym.entity.GymMembership;
import com.fityaar.gym.entity.GymMembership.Role;
import com.fityaar.gym.entity.GymMembership.Status;
import com.fityaar.gym.repository.GymMembershipRepository;
import com.fityaar.gym.repository.GymRepository;
import com.fityaar.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;

import java.util.Locale;

/**
 * Central tenant + role authorization for gym resources. One place decides
 * "who are you, which gym, and are you allowed" so the rules can't drift across services.
 */
@Service
@RequiredArgsConstructor
public class AuthorizationService {

    private final GymRepository gymRepo;
    private final GymMembershipRepository membershipRepo;

    public Gym gym(Long gymId) {
        return gymRepo.findById(gymId)
                .orElseThrow(() -> new ResourceNotFoundException("Gym not found"));
    }

    /** Caller must be an ACTIVE member of the gym. Returns the membership. */
    public GymMembership requireActiveMember(User user, Long gymId) {
        GymMembership m = activeMembership(user, gymId, "Not a member of this gym");
        return m;
    }

    /** Caller must be an ACTIVE TRAINER or OWNER of the gym. */
    public Gym requireTrainerOrOwner(User user, Long gymId) {
        GymMembership m = activeMembership(user, gymId, "Trainers/owners only");
        if (m.getRole() != Role.TRAINER && m.getRole() != Role.OWNER) {
            throw new AccessDeniedException("Trainers/owners only");
        }
        return m.getGym();
    }

    /** Caller must be the ACTIVE OWNER of the gym. */
    public Gym requireOwner(User user, Long gymId) {
        GymMembership m = activeMembership(user, gymId, "Owner only");
        if (m.getRole() != Role.OWNER) {
            throw new AccessDeniedException("Owner only");
        }
        return m.getGym();
    }

    /** Platform super-admin (User.Role.ADMIN) — bypasses tenant scoping. */
    public void requireSuper(User user) {
        if (user.getRole() != User.Role.ADMIN) {
            throw new AccessDeniedException("Super admin only");
        }
    }

    /**
     * Parse + authorize a role the caller wants to assign in this gym.
     * OWNER may assign TRAINER/MEMBER (never OWNER — only super-admin mints owners);
     * TRAINER may assign MEMBER only; MEMBER may assign nobody.
     */
    public Role assignableRole(User caller, Long gymId, String requestedStr) {
        Role requested = parseRole(requestedStr);
        GymMembership cm = activeMembership(caller, gymId, "Not allowed");
        boolean ok = switch (cm.getRole()) {
            case OWNER -> requested == Role.MEMBER || requested == Role.TRAINER;
            case TRAINER -> requested == Role.MEMBER;
            default -> false;
        };
        if (!ok) {
            throw new AccessDeniedException("You cannot assign the " + requested + " role");
        }
        return requested;
    }

    /**
     * Can {@code caller} manage (edit / remove / role-change / assign) the given target membership?
     * Enforces the "manage only people below you" hierarchy: a TRAINER may act on MEMBERs only;
     * an OWNER may act on TRAINERs/MEMBERs but never a peer OWNER; the platform super-admin bypasses.
     * This is the target-rank check that {@link #assignableRole} (which only vets the requested role)
     * does not provide.
     */
    public void requireCanManage(User caller, GymMembership target) {
        if (caller.getRole() == User.Role.ADMIN) return;      // platform super-admin bypasses tenant scoping
        GymMembership cm = activeMembership(caller, target.getGym().getId(), "Not allowed to manage members");
        Role targetRole = target.getRole();
        boolean ok = switch (cm.getRole()) {
            case OWNER -> targetRole == Role.MEMBER || targetRole == Role.TRAINER;
            case TRAINER -> targetRole == Role.MEMBER;
            default -> false;
        };
        if (!ok) {
            throw new AccessDeniedException("You cannot manage a " + targetRole + " member");
        }
    }

    private GymMembership activeMembership(User user, Long gymId, String denyMsg) {
        Gym g = gym(gymId);
        GymMembership m = membershipRepo.findByUserAndGym(user, g)
                .orElseThrow(() -> new AccessDeniedException(denyMsg));
        if (m.getStatus() != Status.ACTIVE) {
            throw new AccessDeniedException(denyMsg);
        }
        return m;
    }

    private Role parseRole(String s) {
        if (s == null || s.isBlank()) return Role.MEMBER;
        try {
            return Role.valueOf(s.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Unknown role: " + s);
        }
    }
}
