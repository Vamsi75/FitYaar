package com.fityaar.social.repository;

import com.fityaar.social.entity.Follow;
import com.fityaar.social.entity.Follow.Status;
import com.fityaar.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FollowRepository extends JpaRepository<Follow, Long> {
    Optional<Follow> findByFollowerAndFollowing(User follower, User following);

    List<Follow> findByFollowerAndStatus(User follower, Status status);   // people I follow
    List<Follow> findByFollowingAndStatus(User following, Status status); // my followers / requests

    long countByFollowerAndStatus(User follower, Status status);
    long countByFollowingAndStatus(User following, Status status);
}
