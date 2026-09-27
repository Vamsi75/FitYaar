package com.fityaar.gym.service;

import com.fityaar.exception.ResourceNotFoundException;
import com.fityaar.gym.dto.ActiveMember;
import com.fityaar.gym.dto.GymActivityItem;
import com.fityaar.gym.dto.GymClassDto;
import com.fityaar.gym.dto.GymEventDto;
import com.fityaar.gym.dto.GymPlanDto;
import com.fityaar.gym.dto.GymSummary;
import com.fityaar.gym.dto.HourlyBucket;
import com.fityaar.gym.dto.LeaderboardEntry;
import com.fityaar.gym.dto.MemberDetail;
import com.fityaar.gym.dto.MembershipView;
import com.fityaar.gym.dto.PlanItemDto;
import com.fityaar.gym.dto.PlanRequest;
import com.fityaar.gym.dto.TrainerDto;
import com.fityaar.gym.entity.Gym;
import com.fityaar.gym.entity.GymCheckin;
import com.fityaar.gym.entity.GymClass;
import com.fityaar.gym.entity.GymEvent;
import com.fityaar.gym.entity.GymMembership;
import com.fityaar.gym.entity.GymMembership.Role;
import com.fityaar.gym.entity.GymMembership.Status;
import com.fityaar.gym.entity.GymPlan;
import com.fityaar.gym.entity.GymPlanItem;
import com.fityaar.gym.repository.GymCheckinRepository;
import com.fityaar.gym.repository.GymClassRepository;
import com.fityaar.gym.repository.GymEventRepository;
import com.fityaar.gym.repository.GymMembershipRepository;
import com.fityaar.gym.repository.GymPlanItemRepository;
import com.fityaar.gym.repository.GymPlanRepository;
import com.fityaar.gym.repository.GymRepository;
import com.fityaar.notification.PushService;
import com.fityaar.security.AuthorizationService;
import com.fityaar.user.entity.User;
import com.fityaar.user.repository.UserRepository;
import com.fityaar.workout.entity.WorkoutSession;
import com.fityaar.workout.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GymService {

    private final GymRepository gymRepo;
    private final GymMembershipRepository membershipRepo;
    private final GymCheckinRepository checkinRepo;
    private final GymEventRepository eventRepo;
    private final GymPlanRepository planRepo;
    private final GymPlanItemRepository planItemRepo;
    private final GymClassRepository classRepo;
    private final UserRepository userRepo;
    private final WorkoutSessionRepository sessionRepo;
    private final NotificationService notificationService;
    private final PushService pushService;
    private final AuthorizationService authz;

    public List<GymSummary> myGyms(User user) {
        return membershipRepo.findByUser(user).stream()
                .map(m -> toSummary(m.getGym(), m))
                .toList();
    }

    /** Members enter joinCode (-> PENDING); owners enter ownerCode (-> OWNER, ACTIVE). */
    @Transactional
    public GymSummary join(User user, String code) {
        Gym gym = gymRepo.findByJoinCode(code).orElse(null);
        boolean asOwner = false;
        if (gym == null) {
            gym = gymRepo.findByOwnerCode(code)
                    .orElseThrow(() -> new ResourceNotFoundException("Invalid gym code"));
            asOwner = true;
        }
        GymMembership m = membershipRepo.findByUserAndGym(user, gym).orElse(null);
        if (m == null) {
            m = GymMembership.builder()
                    .user(user)
                    .gym(gym)
                    .role(asOwner ? Role.OWNER : Role.MEMBER)
                    .status(asOwner ? Status.ACTIVE : Status.PENDING)
                    .build();
        } else if (asOwner) {
            m.setRole(Role.OWNER);
            m.setStatus(Status.ACTIVE);
        }
        membershipRepo.save(m);
        return toSummary(gym, m);
    }

    @Transactional
    public void checkIn(User user, Long gymId, String focus, String zone) {
        GymMembership m = authz.requireActiveMember(user, gymId);
        checkinRepo.findByUserAndGymAndCheckOutAtIsNull(user, m.getGym()).ifPresent(c -> {
            c.setCheckOutAt(LocalDateTime.now());
            checkinRepo.save(c);
        });
        checkinRepo.save(GymCheckin.builder()
                .user(user).gym(m.getGym()).checkInAt(LocalDateTime.now())
                .focus(focus != null && !focus.isBlank() ? focus.trim() : null)
                .zone(zone != null && !zone.isBlank() ? zone.trim() : null)
                .build());
    }

    @Transactional
    public void checkOut(User user, Long gymId) {
        Gym gym = authz.requireActiveMember(user, gymId).getGym();
        checkinRepo.findByUserAndGymAndCheckOutAtIsNull(user, gym).ifPresent(c -> {
            c.setCheckOutAt(LocalDateTime.now());
            checkinRepo.save(c);
        });
    }

    /** Auto-checkout everywhere — called when a workout is finished. */
    @Transactional
    public void checkoutUserEverywhere(User user) {
        List<GymCheckin> open = checkinRepo.findByUserAndCheckOutAtIsNull(user);
        LocalDateTime now = LocalDateTime.now();
        open.forEach(c -> c.setCheckOutAt(now));
        checkinRepo.saveAll(open);
    }

    /** "Who's doing what" — counts of currently checked-in members by focus. */
    public List<GymActivityItem> activity(User user, Long gymId) {
        Gym g = authz.requireActiveMember(user, gymId).getGym();
        Map<String, Long> byFocus = checkinRepo.findByGymAndCheckOutAtIsNull(g).stream()
                .collect(Collectors.groupingBy(
                        c -> c.getFocus() != null ? c.getFocus() : "Training",
                        Collectors.counting()));
        return byFocus.entrySet().stream()
                .sorted((a, b) -> Long.compare(b.getValue(), a.getValue()))
                .map(e -> new GymActivityItem(e.getKey(), e.getValue()))
                .toList();
    }

    /** Live zone occupancy — checked-in members (excluding staff) grouped by zone. */
    public List<GymActivityItem> zones(User user, Long gymId) {
        Gym g = authz.requireActiveMember(user, gymId).getGym();
        Set<Long> staff = staffIds(g);
        Map<String, Long> byZone = checkinRepo.findByGymAndCheckOutAtIsNull(g).stream()
                .filter(c -> !staff.contains(c.getUser().getId()))
                .collect(Collectors.groupingBy(
                        c -> c.getZone() != null ? c.getZone() : "Open gym",
                        Collectors.counting()));
        return byZone.entrySet().stream()
                .sorted((a, b) -> Long.compare(b.getValue(), a.getValue()))
                .map(e -> new GymActivityItem(e.getKey(), e.getValue()))
                .toList();
    }

    /** Busy-by-hour trend: check-in counts per hour of day over the last 30 days. */
    public List<HourlyBucket> trends(User user, Long gymId) {
        Gym g = authz.requireActiveMember(user, gymId).getGym();
        LocalDateTime since = LocalDateTime.now().minusDays(30);
        Map<Integer, Long> byHour = checkinRepo.findByGymAndCheckInAtAfter(g, since).stream()
                .collect(Collectors.groupingBy(c -> c.getCheckInAt().getHour(), Collectors.counting()));
        List<HourlyBucket> out = new ArrayList<>(24);
        for (int h = 0; h < 24; h++) {
            out.add(new HourlyBucket(h, byHour.getOrDefault(h, 0L)));
        }
        return out;
    }

    // ---- events ----

    @Transactional
    public GymEventDto createEvent(User admin, Long gymId, String title, String body, LocalDateTime startsAt) {
        Gym g = authz.requireTrainerOrOwner(admin, gymId);
        GymEvent ev = eventRepo.save(GymEvent.builder()
                .gym(g).title(title).body(body).startsAt(startsAt).build());
        // Push the announcement to the gym's active members (fail-soft; logs if FCM off).
        List<User> members = membershipRepo.findByGymAndStatus(g, Status.ACTIVE).stream()
                .map(GymMembership::getUser)
                .toList();
        pushService.sendToUsers(members, "New from " + g.getName(), title);
        return toEventDto(ev);
    }

    @Transactional
    public GymEventDto updateEvent(User user, Long eventId, String title, String body, LocalDateTime startsAt) {
        GymEvent ev = eventRepo.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Update not found"));
        authz.requireTrainerOrOwner(user, ev.getGym().getId());
        if (title != null && !title.isBlank()) ev.setTitle(title.trim());
        ev.setBody(body != null && !body.isBlank() ? body.trim() : null);
        ev.setStartsAt(startsAt);
        return toEventDto(eventRepo.save(ev));
    }

    @Transactional
    public void deleteEvent(User user, Long eventId) {
        GymEvent ev = eventRepo.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Update not found"));
        authz.requireTrainerOrOwner(user, ev.getGym().getId());
        eventRepo.delete(ev);
    }

    public List<GymEventDto> events(User user, Long gymId) {
        Gym g = authz.requireActiveMember(user, gymId).getGym();
        return eventRepo.findByGymOrderByCreatedAtDesc(g).stream().map(this::toEventDto).toList();
    }

    // ---- G.6: plan of the day / active-now / leaderboard ----

    /** A trainer/owner assigns a structured plan (exercise list) to a client. */
    @Transactional
    public GymPlanDto assignPlan(User user, Long gymId, PlanRequest req) {
        Gym g = authz.requireTrainerOrOwner(user, gymId);
        User client = req.getClientId() != null
                ? userRepo.findById(req.getClientId())
                    .orElseThrow(() -> new ResourceNotFoundException("Client not found"))
                : null;
        if (client != null) {   // targeting a specific client → they must be a member you can manage
            GymMembership cm = membershipRepo.findByUserAndGym(client, g)
                    .orElseThrow(() -> new ResourceNotFoundException("Client not found in this gym"));
            authz.requireCanManage(user, cm);
        }
        GymPlan p = planRepo.save(GymPlan.builder()
                .gym(g).author(user).client(client).planDate(LocalDate.now())
                .title(req.getTitle().trim())
                .body(req.getNote() != null && !req.getNote().isBlank() ? req.getNote().trim() : null)
                .build());
        if (req.getItems() != null) {
            int i = 0;
            for (PlanRequest.PlanItemInput it : req.getItems()) {
                if (it.getExerciseName() == null || it.getExerciseName().isBlank()) continue;
                planItemRepo.save(GymPlanItem.builder()
                        .plan(p).orderIndex(i++)
                        .exerciseName(it.getExerciseName().trim())
                        .sets(it.getSets()).reps(it.getReps())
                        .note(it.getNote() != null && !it.getNote().isBlank() ? it.getNote().trim() : null)
                        .build());
            }
        }
        return toPlanDto(p);
    }

    /** The current user's latest personal plan at this gym (null if none). */
    public GymPlanDto myPlan(User user, Long gymId) {
        Gym g = authz.requireActiveMember(user, gymId).getGym();
        return planRepo.findTopByGymAndClientOrderByPlanDateDescCreatedAtDesc(g, user)
                .map(this::toPlanDto).orElse(null);
    }

    /** Active members — the client picker a trainer chooses from. */
    public List<MembershipView> roster(User user, Long gymId) {
        Gym g = authz.requireTrainerOrOwner(user, gymId);
        return membershipRepo.findByGymAndStatus(g, Status.ACTIVE).stream().map(this::toView).toList();
    }

    /** Full member record for the trainer's member-detail screen. */
    public MemberDetail memberDetail(User user, Long membershipId) {
        GymMembership m = getMembership(membershipId);
        authz.requireTrainerOrOwner(user, m.getGym().getId());
        return toMemberDetail(m);
    }

    /** Trainer/owner edits a member's gym record; notifies the owner + member. */
    @Transactional
    public MemberDetail updateMember(User user, Long membershipId, String phone,
                                     LocalDate expiresAt, String ptNotes) {
        GymMembership m = getMembership(membershipId);
        authz.requireCanManage(user, m);      // can't edit a peer/owner's record
        Gym g = m.getGym();
        List<String> changes = new ArrayList<>();
        if (phone != null && m.getUser().getProfile() != null) {
            m.getUser().getProfile().setPhone(phone.isBlank() ? null : phone.trim());
            changes.add("Phone: " + (phone.isBlank() ? "cleared" : phone.trim()));
            userRepo.save(m.getUser());
        }
        if (expiresAt != null) { m.setExpiresAt(expiresAt); changes.add("Membership expires: " + expiresAt); }
        if (ptNotes != null) {
            m.setPtNotes(ptNotes.isBlank() ? null : ptNotes.trim());
            changes.add("Training notes updated");
        }
        membershipRepo.save(m);
        notificationService.memberUpdated(g.getName(), ownerEmail(g), m.getUser().getEmail(),
                nameOf(m.getUser()), nameOf(user),
                changes.isEmpty() ? "Details reviewed." : String.join("\n", changes));
        return toMemberDetail(m);
    }

    /** Trainer takes a member as a personal-training client (self, or a given trainer). */
    @Transactional
    public MemberDetail setClient(User user, Long membershipId, Long trainerId) {
        GymMembership m = getMembership(membershipId);
        authz.requireCanManage(user, m);
        User trainer = trainerId != null
                ? userRepo.findById(trainerId).orElseThrow(() -> new ResourceNotFoundException("Trainer not found"))
                : user;
        m.setTrainer(trainer);
        return toMemberDetail(membershipRepo.save(m));
    }

    @Transactional
    public MemberDetail unsetClient(User user, Long membershipId) {
        GymMembership m = getMembership(membershipId);
        authz.requireCanManage(user, m);
        m.setTrainer(null);
        return toMemberDetail(membershipRepo.save(m));
    }

    /** Trainers/owners of the gym — names always visible to members; activeNow = checked in right now. */
    public List<TrainerDto> trainers(User user, Long gymId) {
        Gym g = authz.requireActiveMember(user, gymId).getGym();
        Set<Long> here = checkinRepo.findByGymAndCheckOutAtIsNull(g).stream()
                .map(c -> c.getUser().getId()).collect(Collectors.toSet());
        return membershipRepo.findByGymAndStatus(g, Status.ACTIVE).stream()
                .filter(m -> m.getRole() == Role.TRAINER || m.getRole() == Role.OWNER)
                .map(m -> new TrainerDto(m.getUser().getId(), nameOf(m.getUser()), m.getRole().name(),
                        here.contains(m.getUser().getId())))
                .toList();
    }

    // ---- classes ----

    public List<GymClassDto> classes(User user, Long gymId) {
        Gym g = authz.requireActiveMember(user, gymId).getGym();
        return classRepo.findByGymOrderByCreatedAtDesc(g).stream().map(this::toClassDto).toList();
    }

    @Transactional
    public GymClassDto addClass(User user, Long gymId, String title, String schedule, String description) {
        Gym g = authz.requireTrainerOrOwner(user, gymId);
        GymClass c = classRepo.save(GymClass.builder()
                .gym(g).trainer(user).title(title.trim())
                .schedule(schedule != null && !schedule.isBlank() ? schedule.trim() : null)
                .description(description != null && !description.isBlank() ? description.trim() : null)
                .build());
        return toClassDto(c);
    }

    @Transactional
    public void deleteClass(User user, Long classId) {
        GymClass c = classRepo.findById(classId)
                .orElseThrow(() -> new ResourceNotFoundException("Class not found"));
        boolean creator = c.getTrainer().getId().equals(user.getId());
        GymMembership m = membershipRepo.findByUserAndGym(user, c.getGym()).orElse(null);
        boolean owner = m != null && m.getRole() == Role.OWNER && m.getStatus() == Status.ACTIVE;
        if (!creator && !owner) throw new AccessDeniedException("Not allowed");
        classRepo.delete(c);
    }

    /** Members currently checked in (privacy-filtered) — "gymmates active now". */
    public List<ActiveMember> activeMembers(User user, Long gymId) {
        Gym g = authz.requireActiveMember(user, gymId).getGym();
        final Set<Long> staff = staffIds(g);
        return checkinRepo.findByGymAndCheckOutAtIsNull(g).stream()
                .filter(c -> !staff.contains(c.getUser().getId()))
                .filter(c -> isGymVisible(c.getUser()))
                .map(c -> new ActiveMember(nameOf(c.getUser()), c.getFocus()))
                .toList();
    }

    /** Weekly leaderboard (last 7 days) across active members: workouts + volume. */
    public List<LeaderboardEntry> leaderboard(User user, Long gymId) {
        Gym g = authz.requireActiveMember(user, gymId).getGym();
        final Set<Long> staff = staffIds(g);
        List<User> members = membershipRepo.findByGymAndStatus(g, Status.ACTIVE).stream()
                .map(GymMembership::getUser)
                .filter(u -> !staff.contains(u.getId()))
                .filter(this::isGymVisible)
                .toList();
        if (members.isEmpty()) return List.of();
        LocalDateTime since = LocalDateTime.now().minusDays(7);
        Map<Long, long[]> agg = new HashMap<>(); // userId -> [workouts, volume]
        for (WorkoutSession s : sessionRepo.findByUserInAndStartTimeAfter(members, since)) {
            if (s.getUser() == null) continue;
            long[] a = agg.computeIfAbsent(s.getUser().getId(), k -> new long[2]);
            a[0]++;
            a[1] += s.getTotalVolume() != null ? s.getTotalVolume() : 0;
        }
        return members.stream()
                .map(m -> {
                    long[] a = agg.getOrDefault(m.getId(), new long[2]);
                    return new LeaderboardEntry(m.getId(), nameOf(m), a[0], a[1]);
                })
                .sorted((x, y) -> x.workouts() != y.workouts()
                        ? Long.compare(y.workouts(), x.workouts())
                        : Long.compare(y.volume(), x.volume()))
                .toList();
    }

    // ---- admin ----

    public List<MembershipView> pendingRequests(User admin, Long gymId) {
        Gym g = authz.requireTrainerOrOwner(admin, gymId);
        return membershipRepo.findByGymAndStatus(g, Status.PENDING).stream().map(this::toView).toList();
    }

    public List<MembershipView> members(User admin, Long gymId) {
        Gym g = authz.requireTrainerOrOwner(admin, gymId);
        return membershipRepo.findByGymAndStatus(g, Status.ACTIVE).stream().map(this::toView).toList();
    }

    @Transactional
    public MembershipView approve(User admin, Long membershipId) {
        GymMembership m = getMembership(membershipId);
        authz.requireTrainerOrOwner(admin, m.getGym().getId());
        m.setStatus(Status.ACTIVE);
        return toView(membershipRepo.save(m));
    }

    @Transactional
    public void reject(User admin, Long membershipId) {
        GymMembership m = getMembership(membershipId);
        authz.requireTrainerOrOwner(admin, m.getGym().getId());
        m.setStatus(Status.REJECTED);
        membershipRepo.save(m);
    }

    /** Soft-deactivate a member (keeps history; does not delete). */
    @Transactional
    public void remove(User admin, Long membershipId) {
        GymMembership m = getMembership(membershipId);
        authz.requireCanManage(admin, m);      // trainers can't remove owners/other trainers
        m.setStatus(Status.INACTIVE);
        membershipRepo.save(m);
    }

    @Transactional
    public MembershipView addMember(User admin, Long gymId, String email, String roleStr) {
        Gym g = authz.requireTrainerOrOwner(admin, gymId);
        Role role = authz.assignableRole(admin, gymId, roleStr);
        User u = userRepo.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("No user with email " + email));
        GymMembership m = membershipRepo.findByUserAndGym(u, g)
                .orElse(GymMembership.builder().user(u).gym(g).build());
        m.setRole(role);
        m.setStatus(Status.ACTIVE);
        return toView(membershipRepo.save(m));
    }

    @Transactional
    public MembershipView changeRole(User admin, Long membershipId, String roleStr) {
        GymMembership m = getMembership(membershipId);
        authz.requireOwner(admin, m.getGym().getId());
        authz.requireCanManage(admin, m);     // can't change a peer owner's role
        m.setRole(authz.assignableRole(admin, m.getGym().getId(), roleStr));
        return toView(membershipRepo.save(m));
    }

    @Transactional
    public GymSummary updateBanner(User admin, Long gymId, String text) {
        Gym g = authz.requireTrainerOrOwner(admin, gymId);
        g.setBannerText(text);
        gymRepo.save(g);
        GymMembership m = membershipRepo.findByUserAndGym(admin, g).orElse(null);
        return toSummary(g, m);
    }

    // ---- helpers ----

    private GymMembership getMembership(Long id) {
        return membershipRepo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Membership not found"));
    }

    private GymSummary toSummary(Gym g, GymMembership m) {
        boolean checkedIn = m != null && m.getStatus() == Status.ACTIVE
                && checkinRepo.findByUserAndGymAndCheckOutAtIsNull(m.getUser(), g).isPresent();
        final Set<Long> staff = staffIds(g);
        final long live = checkinRepo.findByGymAndCheckOutAtIsNull(g).stream()
                .filter(c -> !staff.contains(c.getUser().getId()))
                .count();
        return GymSummary.builder()
                .gymId(g.getId())
                .name(g.getName())
                .bannerText(g.getBannerText())
                .capacity(g.getCapacity())
                .liveCount(live)
                .membershipId(m != null ? m.getId() : null)
                .role(m != null ? m.getRole().name() : null)
                .status(m != null ? m.getStatus().name() : null)
                .admin(m != null && m.getRole() == Role.OWNER && m.getStatus() == Status.ACTIVE)
                .checkedIn(checkedIn)
                .build();
    }

    private MembershipView toView(GymMembership m) {
        String name = m.getUser().getProfile() != null
                ? m.getUser().getProfile().getDisplayName() : null;
        return MembershipView.builder()
                .membershipId(m.getId())
                .userId(m.getUser().getId())
                .displayName(name)
                .email(m.getUser().getEmail())
                .role(m.getRole().name())
                .status(m.getStatus().name())
                .joinedAt(m.getCreatedAt() != null ? m.getCreatedAt().toLocalDate() : null)
                .build();
    }

    private String nameOf(User u) {
        if (u.getProfile() != null && u.getProfile().getDisplayName() != null
                && !u.getProfile().getDisplayName().isBlank()) {
            return u.getProfile().getDisplayName();
        }
        return u.getEmail();
    }

    private GymPlanDto toPlanDto(GymPlan p) {
        List<PlanItemDto> items = planItemRepo.findByPlanOrderByOrderIndex(p).stream()
                .map(it -> new PlanItemDto(it.getExerciseName(), it.getSets(), it.getReps(), it.getNote()))
                .toList();
        return new GymPlanDto(p.getId(), p.getTitle(), p.getBody(), p.getPlanDate(), nameOf(p.getAuthor()), items);
    }

    private GymClassDto toClassDto(GymClass c) {
        return new GymClassDto(c.getId(), c.getTitle(), c.getSchedule(), c.getDescription(), nameOf(c.getTrainer()));
    }

    private boolean isGymVisible(User u) {
        return u.getProfile() == null || u.getProfile().getGymVisible() == null
                || u.getProfile().getGymVisible();
    }

    private MemberDetail toMemberDetail(GymMembership m) {
        var p = m.getUser().getProfile();
        return new MemberDetail(
                m.getId(), m.getUser().getId(), nameOf(m.getUser()), m.getUser().getEmail(),
                p != null ? p.getPhone() : null, m.getRole().name(), m.getStatus().name(),
                m.getCreatedAt() != null ? m.getCreatedAt().toLocalDate() : null,
                m.getExpiresAt(), m.getTrainer() != null ? nameOf(m.getTrainer()) : null, m.getPtNotes());
    }

    private String ownerEmail(Gym g) {
        return membershipRepo.findByGymAndStatus(g, Status.ACTIVE).stream()
                .filter(m -> m.getRole() == Role.OWNER)
                .map(m -> m.getUser().getEmail()).findFirst().orElse(null);
    }

    /** Active TRAINER/OWNER user ids — treated as staff (excluded from crowd). */
    private Set<Long> staffIds(Gym g) {
        return membershipRepo.findByGymAndStatus(g, Status.ACTIVE).stream()
                .filter(m -> m.getRole() == Role.TRAINER || m.getRole() == Role.OWNER)
                .map(m -> m.getUser().getId())
                .collect(Collectors.toSet());
    }

    private GymEventDto toEventDto(GymEvent e) {
        return GymEventDto.builder()
                .id(e.getId())
                .title(e.getTitle())
                .body(e.getBody())
                .startsAt(e.getStartsAt())
                .createdAt(e.getCreatedAt())
                .build();
    }
}
