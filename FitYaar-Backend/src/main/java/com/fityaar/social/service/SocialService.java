package com.fityaar.social.service;

import com.fityaar.exception.ResourceNotFoundException;
import com.fityaar.social.dto.CompareStats;
import com.fityaar.social.dto.FeedItem;
import com.fityaar.social.dto.PublicProfile;
import com.fityaar.social.dto.SocialCounts;
import com.fityaar.social.dto.UserSummary;
import com.fityaar.social.entity.Follow;
import com.fityaar.social.entity.Follow.Status;
import com.fityaar.social.repository.FollowRepository;
import com.fityaar.user.entity.User;
import com.fityaar.user.repository.UserRepository;
import com.fityaar.workout.entity.WorkoutSession;
import com.fityaar.workout.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SocialService {

    private final FollowRepository followRepo;
    private final UserRepository userRepo;
    private final WorkoutSessionRepository sessionRepo;

    public List<UserSummary> search(User me, String q) {
        if (q == null || q.isBlank()) return List.of();
        return userRepo.searchUsers(q.trim(), me.getId()).stream()
                .map(u -> toSummary(me, u)).toList();
    }

    @Transactional
    public UserSummary follow(User me, Long targetId) {
        User target = getUser(targetId);
        if (target.getId().equals(me.getId())) {
            throw new IllegalStateException("You can't follow yourself");
        }
        if (followRepo.findByFollowerAndFollowing(me, target).isEmpty()) {
            followRepo.save(Follow.builder()
                    .follower(me).following(target)
                    .status(isPublic(target) ? Status.ACCEPTED : Status.PENDING)
                    .build());
        }
        return toSummary(me, target);
    }

    @Transactional
    public void unfollow(User me, Long targetId) {
        User target = getUser(targetId);
        followRepo.findByFollowerAndFollowing(me, target).ifPresent(followRepo::delete);
    }

    public List<UserSummary> incomingRequests(User me) {
        return followRepo.findByFollowingAndStatus(me, Status.PENDING).stream()
                .map(f -> toSummary(me, f.getFollower())).toList();
    }

    @Transactional
    public void approve(User me, Long followerUserId) {
        User follower = getUser(followerUserId);
        Follow f = followRepo.findByFollowerAndFollowing(follower, me)
                .orElseThrow(() -> new ResourceNotFoundException("No pending request"));
        f.setStatus(Status.ACCEPTED);
        followRepo.save(f);
    }

    @Transactional
    public void reject(User me, Long followerUserId) {
        User follower = getUser(followerUserId);
        followRepo.findByFollowerAndFollowing(follower, me).ifPresent(followRepo::delete);
    }

    public List<UserSummary> followers(User me, Long userId) {
        User target = getUser(userId);
        requireView(me, target);
        return followRepo.findByFollowingAndStatus(target, Status.ACCEPTED).stream()
                .map(f -> toSummary(me, f.getFollower())).toList();
    }

    public List<UserSummary> following(User me, Long userId) {
        User target = getUser(userId);
        requireView(me, target);
        return followRepo.findByFollowerAndStatus(target, Status.ACCEPTED).stream()
                .map(f -> toSummary(me, f.getFollowing())).toList();
    }

    public PublicProfile profile(User me, Long userId) {
        User target = getUser(userId);
        boolean self = target.getId().equals(me.getId());
        boolean canView = self || isPublic(target) || accepted(me, target);
        var p = target.getProfile();
        return PublicProfile.builder()
                .userId(target.getId())
                .displayName(p != null ? p.getDisplayName() : null)
                .bio(canView && p != null ? p.getBio() : null)
                .profilePictureUrl(p != null ? p.getProfilePictureUrl() : null)
                .isPublic(isPublic(target))
                .followersCount(followRepo.countByFollowingAndStatus(target, Status.ACCEPTED))
                .followingCount(followRepo.countByFollowerAndStatus(target, Status.ACCEPTED))
                .workoutsCount(canView ? sessionRepo.countByUser(target) : 0)
                .followStatus(followStatus(me, target))
                .canView(canView)
                .self(self)
                .build();
    }

    public CompareStats compare(User me, Long userId) {
        User target = getUser(userId);
        requireView(me, target);
        return CompareStats.builder()
                .meName(name(me)).themName(name(target))
                .me(stats(me)).them(stats(target)).build();
    }

    public List<FeedItem> feed(User me) {
        List<User> following = followRepo.findByFollowerAndStatus(me, Status.ACCEPTED)
                .stream().map(Follow::getFollowing).toList();
        if (following.isEmpty()) return List.of();
        return sessionRepo.findTop50ByUserInOrderByStartTimeDesc(following).stream()
                .map(this::toFeedItem).toList();
    }

    public SocialCounts myCounts(User me) {
        return SocialCounts.builder()
                .followers(followRepo.countByFollowingAndStatus(me, Status.ACCEPTED))
                .following(followRepo.countByFollowerAndStatus(me, Status.ACCEPTED))
                .pendingRequests(followRepo.countByFollowingAndStatus(me, Status.PENDING))
                .build();
    }

    // ---- helpers ----

    private User getUser(Long id) {
        return userRepo.findById(id).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private boolean isPublic(User u) {
        return u.getProfile() == null || u.getProfile().getIsPublic() == null || u.getProfile().getIsPublic();
    }

    private boolean accepted(User me, User target) {
        return followRepo.findByFollowerAndFollowing(me, target)
                .map(f -> f.getStatus() == Status.ACCEPTED).orElse(false);
    }

    private void requireView(User me, User target) {
        if (!(target.getId().equals(me.getId()) || isPublic(target) || accepted(me, target))) {
            throw new AccessDeniedException("This profile is private");
        }
    }

    private String followStatus(User me, User target) {
        if (target.getId().equals(me.getId())) return "SELF";
        return followRepo.findByFollowerAndFollowing(me, target)
                .map(f -> f.getStatus() == Status.ACCEPTED ? "FOLLOWING" : "PENDING")
                .orElse("NONE");
    }

    private String name(User u) {
        return u.getProfile() != null && u.getProfile().getDisplayName() != null
                ? u.getProfile().getDisplayName() : u.getEmail();
    }

    private UserSummary toSummary(User me, User u) {
        var p = u.getProfile();
        return UserSummary.builder()
                .userId(u.getId())
                .displayName(p != null && p.getDisplayName() != null ? p.getDisplayName() : u.getEmail())
                .profilePictureUrl(p != null ? p.getProfilePictureUrl() : null)
                .isPublic(isPublic(u))
                .followStatus(followStatus(me, u))
                .build();
    }

    private CompareStats.StatBlock stats(User u) {
        List<WorkoutSession> sessions = sessionRepo.findByUserOrderByStartTimeDesc(u);
        long sets = 0, volume = 0, minutes = 0;
        for (var s : sessions) {
            volume += s.getTotalVolume() != null ? s.getTotalVolume() : 0;
            for (var we : s.getExercises()) {
                sets += we.getSets().size();
            }
            if (s.getStartTime() != null && s.getEndTime() != null) {
                minutes += Duration.between(s.getStartTime(), s.getEndTime()).toMinutes();
            }
        }
        return CompareStats.StatBlock.builder()
                .workouts(sessions.size()).sets(sets).volume(volume).minutes(minutes).build();
    }

    private FeedItem toFeedItem(WorkoutSession s) {
        int sets = 0;
        for (var we : s.getExercises()) {
            sets += we.getSets().size();
        }
        return FeedItem.builder()
                .sessionId(s.getId())
                .name(s.getName())
                .startTime(s.getStartTime())
                .exercisesCount(s.getExercises().size())
                .sets(sets)
                .volume(s.getTotalVolume() != null ? s.getTotalVolume() : 0)
                .authorId(s.getUser().getId())
                .authorName(name(s.getUser()))
                .build();
    }
}
