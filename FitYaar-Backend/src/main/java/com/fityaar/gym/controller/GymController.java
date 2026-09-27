package com.fityaar.gym.controller;

import com.fityaar.gym.dto.ActiveMember;
import com.fityaar.gym.dto.ClassRequest;
import com.fityaar.gym.dto.GymActivityItem;
import com.fityaar.gym.dto.GymClassDto;
import com.fityaar.gym.dto.GymEventDto;
import com.fityaar.gym.dto.GymPlanDto;
import com.fityaar.gym.dto.HourlyBucket;
import com.fityaar.gym.dto.LeaderboardEntry;
import com.fityaar.gym.dto.MemberDetail;
import com.fityaar.gym.dto.MemberUpdateRequest;
import com.fityaar.gym.dto.PlanRequest;
import com.fityaar.gym.dto.RoleRequest;
import com.fityaar.gym.dto.TrainerDto;
import com.fityaar.gym.dto.GymRequests.AddMemberRequest;
import com.fityaar.gym.dto.GymRequests.BannerRequest;
import com.fityaar.gym.dto.GymRequests.CheckinRequest;
import com.fityaar.gym.dto.GymRequests.CreateEventRequest;
import com.fityaar.gym.dto.GymRequests.JoinRequest;
import com.fityaar.gym.dto.GymSummary;
import com.fityaar.gym.dto.MembershipView;
import com.fityaar.gym.service.GymService;
import com.fityaar.security.UserPrincipal;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/gyms")
@RequiredArgsConstructor
public class GymController {

    private final GymService gymService;

    @GetMapping("/me")
    public ResponseEntity<List<GymSummary>> myGyms(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.myGyms(principal.getUser()));
    }

    @PostMapping("/join")
    public ResponseEntity<GymSummary> join(@Valid @RequestBody JoinRequest request,
                                           @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.join(principal.getUser(), request.getCode().trim()));
    }

    @PostMapping("/{gymId}/checkin")
    public ResponseEntity<Void> checkIn(@PathVariable Long gymId,
                                        @RequestBody(required = false) CheckinRequest request,
                                        @AuthenticationPrincipal UserPrincipal principal) {
        gymService.checkIn(principal.getUser(), gymId,
                request != null ? request.getFocus() : null,
                request != null ? request.getZone() : null);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{gymId}/checkout")
    public ResponseEntity<Void> checkOut(@PathVariable Long gymId,
                                         @AuthenticationPrincipal UserPrincipal principal) {
        gymService.checkOut(principal.getUser(), gymId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{gymId}/activity")
    public ResponseEntity<List<GymActivityItem>> activity(@PathVariable Long gymId,
                                                          @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.activity(principal.getUser(), gymId));
    }

    @GetMapping("/{gymId}/zones")
    public ResponseEntity<List<GymActivityItem>> zones(@PathVariable Long gymId,
                                                       @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.zones(principal.getUser(), gymId));
    }

    @GetMapping("/{gymId}/trends")
    public ResponseEntity<List<HourlyBucket>> trends(@PathVariable Long gymId,
                                                     @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.trends(principal.getUser(), gymId));
    }

    @GetMapping("/{gymId}/events")
    public ResponseEntity<List<GymEventDto>> events(@PathVariable Long gymId,
                                                    @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.events(principal.getUser(), gymId));
    }

    @PostMapping("/{gymId}/events")
    public ResponseEntity<GymEventDto> createEvent(@PathVariable Long gymId,
                                                   @Valid @RequestBody CreateEventRequest request,
                                                   @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.createEvent(
                principal.getUser(), gymId, request.getTitle(), request.getBody(), request.getStartsAt()));
    }

    // ---- G.6: plan of the day / active-now / leaderboard ----

    @GetMapping("/{gymId}/plan/me")
    public ResponseEntity<GymPlanDto> myPlan(@PathVariable Long gymId,
                                             @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.myPlan(principal.getUser(), gymId));
    }

    @PostMapping("/{gymId}/plan")
    public ResponseEntity<GymPlanDto> assignPlan(@PathVariable Long gymId,
                                                 @Valid @RequestBody PlanRequest request,
                                                 @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.assignPlan(principal.getUser(), gymId, request));
    }

    @GetMapping("/{gymId}/trainers")
    public ResponseEntity<List<TrainerDto>> trainers(@PathVariable Long gymId,
                                                     @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.trainers(principal.getUser(), gymId));
    }

    // ---- member records (trainer/admin) ----

    @GetMapping("/members/{membershipId}")
    public ResponseEntity<MemberDetail> memberDetail(@PathVariable Long membershipId,
                                                     @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.memberDetail(principal.getUser(), membershipId));
    }

    @PutMapping("/members/{membershipId}")
    public ResponseEntity<MemberDetail> updateMember(@PathVariable Long membershipId,
                                                     @RequestBody MemberUpdateRequest request,
                                                     @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.updateMember(principal.getUser(), membershipId,
                request.getPhone(), request.getExpiresAt(), request.getPtNotes()));
    }

    @PostMapping("/members/{membershipId}/client")
    public ResponseEntity<MemberDetail> setClient(@PathVariable Long membershipId,
                                                  @RequestParam(required = false) Long trainerId,
                                                  @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.setClient(principal.getUser(), membershipId, trainerId));
    }

    @DeleteMapping("/members/{membershipId}/client")
    public ResponseEntity<MemberDetail> unsetClient(@PathVariable Long membershipId,
                                                    @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.unsetClient(principal.getUser(), membershipId));
    }

    @PutMapping("/events/{eventId}")
    public ResponseEntity<GymEventDto> updateEvent(@PathVariable Long eventId,
                                                   @Valid @RequestBody CreateEventRequest request,
                                                   @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.updateEvent(principal.getUser(), eventId,
                request.getTitle(), request.getBody(), request.getStartsAt()));
    }

    @DeleteMapping("/events/{eventId}")
    public ResponseEntity<Void> deleteEvent(@PathVariable Long eventId,
                                            @AuthenticationPrincipal UserPrincipal principal) {
        gymService.deleteEvent(principal.getUser(), eventId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{gymId}/roster")
    public ResponseEntity<List<MembershipView>> roster(@PathVariable Long gymId,
                                                       @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.roster(principal.getUser(), gymId));
    }

    @GetMapping("/{gymId}/classes")
    public ResponseEntity<List<GymClassDto>> classes(@PathVariable Long gymId,
                                                     @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.classes(principal.getUser(), gymId));
    }

    @PostMapping("/{gymId}/classes")
    public ResponseEntity<GymClassDto> addClass(@PathVariable Long gymId,
                                                @Valid @RequestBody ClassRequest request,
                                                @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.addClass(principal.getUser(), gymId,
                request.getTitle(), request.getSchedule(), request.getDescription()));
    }

    @DeleteMapping("/classes/{id}")
    public ResponseEntity<Void> deleteClass(@PathVariable Long id,
                                            @AuthenticationPrincipal UserPrincipal principal) {
        gymService.deleteClass(principal.getUser(), id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{gymId}/active")
    public ResponseEntity<List<ActiveMember>> active(@PathVariable Long gymId,
                                                     @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.activeMembers(principal.getUser(), gymId));
    }

    @GetMapping("/{gymId}/leaderboard")
    public ResponseEntity<List<LeaderboardEntry>> leaderboard(@PathVariable Long gymId,
                                                              @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.leaderboard(principal.getUser(), gymId));
    }

    // ---- admin ----

    @GetMapping("/{gymId}/requests")
    public ResponseEntity<List<MembershipView>> requests(@PathVariable Long gymId,
                                                         @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.pendingRequests(principal.getUser(), gymId));
    }

    @GetMapping("/{gymId}/members")
    public ResponseEntity<List<MembershipView>> members(@PathVariable Long gymId,
                                                        @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.members(principal.getUser(), gymId));
    }

    @PostMapping("/{gymId}/members")
    public ResponseEntity<MembershipView> addMember(@PathVariable Long gymId,
                                                    @Valid @RequestBody AddMemberRequest request,
                                                    @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.addMember(
                principal.getUser(), gymId, request.getEmail().trim(), request.getRole()));
    }

    @PostMapping("/memberships/{id}/approve")
    public ResponseEntity<MembershipView> approve(@PathVariable Long id,
                                                  @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.approve(principal.getUser(), id));
    }

    @PostMapping("/memberships/{id}/reject")
    public ResponseEntity<Void> reject(@PathVariable Long id,
                                       @AuthenticationPrincipal UserPrincipal principal) {
        gymService.reject(principal.getUser(), id);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/memberships/{id}")
    public ResponseEntity<Void> remove(@PathVariable Long id,
                                       @AuthenticationPrincipal UserPrincipal principal) {
        gymService.remove(principal.getUser(), id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/memberships/{id}/role")
    public ResponseEntity<MembershipView> changeRole(@PathVariable Long id,
                                                     @Valid @RequestBody RoleRequest request,
                                                     @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.changeRole(principal.getUser(), id, request.getRole()));
    }

    @PutMapping("/{gymId}/banner")
    public ResponseEntity<GymSummary> updateBanner(@PathVariable Long gymId,
                                                   @Valid @RequestBody BannerRequest request,
                                                   @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(gymService.updateBanner(principal.getUser(), gymId, request.getText()));
    }
}
