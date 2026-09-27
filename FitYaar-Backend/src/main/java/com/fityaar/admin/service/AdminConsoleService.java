package com.fityaar.admin.service;

import com.fityaar.admin.AdminBillingProperties;
import com.fityaar.admin.dto.AdminSubscriptionRow;
import com.fityaar.admin.dto.AdminUserDetail;
import com.fityaar.admin.dto.AdminUserRow;
import com.fityaar.admin.dto.PlatformOverview;
import com.fityaar.admin.dto.TimeSeriesPoint;
import com.fityaar.exception.ResourceNotFoundException;
import com.fityaar.gym.dto.MembershipView;
import com.fityaar.gym.entity.Gym;
import com.fityaar.gym.entity.GymMembership;
import com.fityaar.gym.repository.GymCheckinRepository;
import com.fityaar.gym.repository.GymMembershipRepository;
import com.fityaar.gym.repository.GymRepository;
import com.fityaar.security.AuthorizationService;
import com.fityaar.subscription.dto.EntitlementView;
import com.fityaar.subscription.entity.Subscription;
import com.fityaar.subscription.repository.SubscriptionRepository;
import com.fityaar.subscription.service.EntitlementService;
import com.fityaar.user.entity.Profile;
import com.fityaar.user.entity.User;
import com.fityaar.user.repository.UserRepository;
import com.fityaar.workout.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;

/** Read-only aggregation + listing for the super-admin management portal. */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminConsoleService {

    private static final int EXPIRY_WINDOW_DAYS = 14;

    private final UserRepository userRepo;
    private final WorkoutSessionRepository workoutRepo;
    private final GymRepository gymRepo;
    private final GymMembershipRepository membershipRepo;
    private final GymCheckinRepository checkinRepo;
    private final SubscriptionRepository subscriptionRepo;
    private final EntitlementService entitlementService;
    private final AuthorizationService authz;
    private final AdminBillingProperties billing;

    // ---------------------------------------------------------------- metrics

    public PlatformOverview overview(User admin) {
        authz.requireSuper(admin);
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime d1 = now.minusDays(1), d7 = now.minusDays(7), d30 = now.minusDays(30);
        LocalDateTime soon = now.plusDays(EXPIRY_WINDOW_DAYS);

        List<Gym> gyms = gymRepo.findAll();
        long liveCheckins = 0, gymsWithActivePlan = 0, gymsOverCap = 0, plansExpiringSoon = 0, mrr = 0;
        for (Gym g : gyms) {
            liveCheckins += checkinRepo.countByGymAndCheckOutAtIsNull(g);
            boolean planActive = g.getPlanStatus() == Gym.PlanStatus.ACTIVE
                    && (g.getPlanCurrentPeriodEnd() == null || g.getPlanCurrentPeriodEnd().isAfter(now));
            if (planActive) {
                gymsWithActivePlan++;
                mrr += billing.getPlanPricesPaise().getOrDefault(
                        g.getPlanTier() == null ? "" : g.getPlanTier().trim().toUpperCase(Locale.ROOT), 0L);
                if (g.getPlanCurrentPeriodEnd() != null && g.getPlanCurrentPeriodEnd().isBefore(soon)) {
                    plansExpiringSoon++;
                }
            }
            Integer seats = g.getPaidSeats();
            if (seats != null && membershipRepo.findByGymAndStatus(g, GymMembership.Status.ACTIVE).size() > seats) {
                gymsOverCap++;
            }
        }

        List<Subscription> activeSubs = subscriptionRepo.findByStatus(Subscription.Status.ACTIVE).stream()
                .filter(s -> s.getCurrentPeriodEnd() == null || s.getCurrentPeriodEnd().isAfter(now))
                .toList();
        Map<String, Long> byPlan = new LinkedHashMap<>();
        Map<String, Long> bySource = new LinkedHashMap<>();
        long subsExpiringSoon = 0;
        for (Subscription s : activeSubs) {
            byPlan.merge(s.getPlan().name(), 1L, Long::sum);
            bySource.merge(s.getSource().name(), 1L, Long::sum);
            if (s.getCurrentPeriodEnd() != null && s.getCurrentPeriodEnd().isBefore(soon)) subsExpiringSoon++;
        }

        return PlatformOverview.builder()
                .totalUsers(userRepo.count())
                .activeUsers(userRepo.countByStatus(User.Status.ACTIVE))
                .suspendedUsers(userRepo.countByStatus(User.Status.SUSPENDED))
                .newUsers7d(userRepo.countByCreatedAtAfter(d7))
                .newUsers30d(userRepo.countByCreatedAtAfter(d30))
                .totalGyms(gyms.size())
                .gymsWithActivePlan(gymsWithActivePlan)
                .totalOwners(membershipRepo.countByStatusAndRole(GymMembership.Status.ACTIVE, GymMembership.Role.OWNER))
                .totalTrainers(membershipRepo.countByStatusAndRole(GymMembership.Status.ACTIVE, GymMembership.Role.TRAINER))
                .activeMembers(membershipRepo.countByStatusAndRole(GymMembership.Status.ACTIVE, GymMembership.Role.MEMBER))
                .liveCheckins(liveCheckins)
                .workouts24h(workoutRepo.countByStartTimeAfter(d1))
                .workouts7d(workoutRepo.countByStartTimeAfter(d7))
                .workouts30d(workoutRepo.countByStartTimeAfter(d30))
                .totalWorkouts(workoutRepo.count())
                .activeProSubscribers(activeSubs.size())
                .subsByPlan(byPlan)
                .subsBySource(bySource)
                .estimatedMrrPaise(mrr)
                .gymsOverCap(gymsOverCap)
                .plansExpiringSoon(plansExpiringSoon)
                .subsExpiringSoon(subsExpiringSoon)
                .build();
    }

    public List<TimeSeriesPoint> timeseries(User admin, String metric, int days) {
        authz.requireSuper(admin);
        int span = Math.min(Math.max(days, 1), 365);
        LocalDate start = LocalDate.now().minusDays(span - 1L);
        LocalDateTime after = start.atStartOfDay();

        boolean workouts = "workouts".equalsIgnoreCase(metric);
        List<LocalDateTime> stamps = workouts
                ? workoutRepo.startTimesSince(after)
                : userRepo.createdAtSince(after);

        // Seed every day in range at 0 so the line has no gaps, then tally.
        TreeMap<LocalDate, Long> buckets = new TreeMap<>();
        for (int i = 0; i < span; i++) buckets.put(start.plusDays(i), 0L);
        for (LocalDateTime t : stamps) {
            if (t == null) continue;
            LocalDate d = t.toLocalDate();
            if (buckets.containsKey(d)) buckets.merge(d, 1L, Long::sum);
        }
        List<TimeSeriesPoint> out = new ArrayList<>(buckets.size());
        buckets.forEach((d, c) -> out.add(new TimeSeriesPoint(d, c)));
        return out;
    }

    // ------------------------------------------------------------------ users

    public Page<AdminUserRow> users(User admin, String q, String role, String status, int page, int size) {
        authz.requireSuper(admin);
        PageRequest pr = PageRequest.of(page, Math.min(size, 200), Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<User> found = userRepo.adminSearch(
                likePattern(q),
                parse(User.Status.class, status),
                parse(User.Role.class, role),
                pr);
        return found.map(u -> AdminUserRow.builder()
                .id(u.getId())
                .email(u.getEmail())
                .displayName(u.getProfile() != null ? u.getProfile().getDisplayName() : null)
                .role(u.getRole() == null ? null : u.getRole().name())
                .status(u.getStatus() == null ? null : u.getStatus().name())
                .createdAt(u.getCreatedAt())
                .build());
    }

    public AdminUserDetail userDetail(User admin, Long id) {
        authz.requireSuper(admin);
        User u = userRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        Profile p = u.getProfile();
        EntitlementView ent = entitlementService.view(u);

        List<MembershipView> memberships = membershipRepo.findByUser(u).stream()
                .map(m -> {
                    Gym g = m.getGym();
                    return MembershipView.builder()
                            .membershipId(m.getId()).userId(u.getId())
                            .displayName(p != null ? p.getDisplayName() : null)
                            .email(u.getEmail()).role(m.getRole().name()).status(m.getStatus().name())
                            .joinedAt(m.getCreatedAt() == null ? null : m.getCreatedAt().toLocalDate())
                            .gymId(g.getId()).gymName(g.getName())
                            .build();
                })
                .toList();

        return AdminUserDetail.builder()
                .id(u.getId()).email(u.getEmail())
                .role(u.getRole() == null ? null : u.getRole().name())
                .status(u.getStatus() == null ? null : u.getStatus().name())
                .createdAt(u.getCreatedAt()).updatedAt(u.getUpdatedAt())
                .displayName(p != null ? p.getDisplayName() : null)
                .phone(p != null ? p.getPhone() : null)
                .gender(p != null ? p.getGender() : null)
                .birthday(p != null ? p.getBirthday() : null)
                .fitnessGoal(p != null ? p.getFitnessGoal() : null)
                .pro(ent.isPro()).plan(ent.getPlan()).source(ent.getSource()).proUntil(ent.getUntil())
                .workoutCount(workoutRepo.countByUser(u))
                .memberships(memberships)
                .build();
    }

    // ---------------------------------------------------------- subscriptions

    public Page<AdminSubscriptionRow> subscriptions(User admin, String status, String source,
                                                    String plan, String q, int page, int size) {
        authz.requireSuper(admin);
        PageRequest pr = PageRequest.of(page, Math.min(size, 200), Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<Subscription> found = subscriptionRepo.adminSearch(
                parse(Subscription.Status.class, status),
                parse(Subscription.Source.class, source),
                parse(Subscription.Plan.class, plan),
                likePattern(q),
                pr);
        return found.map(s -> {
            User u = s.getUser();
            Profile p = u.getProfile();
            return AdminSubscriptionRow.builder()
                    .id(s.getId()).userId(u.getId()).email(u.getEmail())
                    .displayName(p != null ? p.getDisplayName() : null)
                    .source(s.getSource().name()).plan(s.getPlan().name()).status(s.getStatus().name())
                    .currentPeriodEnd(s.getCurrentPeriodEnd()).providerRef(s.getProviderRef())
                    .createdAt(s.getCreatedAt())
                    .build();
        });
    }

    // ----------------------------------------------------------------- helpers

    /** Pre-lowercased %...% LIKE pattern, or null for no text filter. */
    private static String likePattern(String q) {
        return q == null || q.isBlank() ? null : "%" + q.trim().toLowerCase(Locale.ROOT) + "%";
    }

    /** Parse an enum filter; blank = no filter (null); unknown value = 400 via IllegalArgumentException. */
    private static <E extends Enum<E>> E parse(Class<E> type, String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return Enum.valueOf(type, value.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid " + type.getSimpleName() + ": " + value);
        }
    }
}
