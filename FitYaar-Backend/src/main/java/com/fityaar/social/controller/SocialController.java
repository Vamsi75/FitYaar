package com.fityaar.social.controller;

import com.fityaar.social.dto.CompareStats;
import com.fityaar.social.dto.FeedItem;
import com.fityaar.social.dto.PublicProfile;
import com.fityaar.social.dto.SocialCounts;
import com.fityaar.social.dto.UserSummary;
import com.fityaar.social.service.SocialService;
import com.fityaar.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/social")
@RequiredArgsConstructor
public class SocialController {

    private final SocialService socialService;

    @GetMapping("/search")
    public ResponseEntity<List<UserSummary>> search(@RequestParam(defaultValue = "") String q,
                                                    @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(socialService.search(principal.getUser(), q));
    }

    @PostMapping("/follow/{userId}")
    public ResponseEntity<UserSummary> follow(@PathVariable Long userId,
                                              @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(socialService.follow(principal.getUser(), userId));
    }

    @DeleteMapping("/follow/{userId}")
    public ResponseEntity<Void> unfollow(@PathVariable Long userId,
                                         @AuthenticationPrincipal UserPrincipal principal) {
        socialService.unfollow(principal.getUser(), userId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/requests")
    public ResponseEntity<List<UserSummary>> requests(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(socialService.incomingRequests(principal.getUser()));
    }

    @PostMapping("/requests/{userId}/approve")
    public ResponseEntity<Void> approve(@PathVariable Long userId,
                                        @AuthenticationPrincipal UserPrincipal principal) {
        socialService.approve(principal.getUser(), userId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/requests/{userId}/reject")
    public ResponseEntity<Void> reject(@PathVariable Long userId,
                                       @AuthenticationPrincipal UserPrincipal principal) {
        socialService.reject(principal.getUser(), userId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/users/{userId}")
    public ResponseEntity<PublicProfile> profile(@PathVariable Long userId,
                                                 @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(socialService.profile(principal.getUser(), userId));
    }

    @GetMapping("/users/{userId}/followers")
    public ResponseEntity<List<UserSummary>> followers(@PathVariable Long userId,
                                                       @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(socialService.followers(principal.getUser(), userId));
    }

    @GetMapping("/users/{userId}/following")
    public ResponseEntity<List<UserSummary>> following(@PathVariable Long userId,
                                                       @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(socialService.following(principal.getUser(), userId));
    }

    @GetMapping("/users/{userId}/compare")
    public ResponseEntity<CompareStats> compare(@PathVariable Long userId,
                                                @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(socialService.compare(principal.getUser(), userId));
    }

    @GetMapping("/feed")
    public ResponseEntity<List<FeedItem>> feed(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(socialService.feed(principal.getUser()));
    }

    @GetMapping("/me/counts")
    public ResponseEntity<SocialCounts> counts(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(socialService.myCounts(principal.getUser()));
    }
}
