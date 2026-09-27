package com.fityaar.workout.repository;

import com.fityaar.user.entity.User;
import com.fityaar.workout.entity.WorkoutSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface WorkoutSessionRepository extends JpaRepository<WorkoutSession, Long> {
    List<WorkoutSession> findByUserOrderByStartTimeDesc(User user);
    List<WorkoutSession> findTop50ByUserInOrderByStartTimeDesc(List<User> users);
    List<WorkoutSession> findByUserInAndStartTimeAfter(List<User> users, LocalDateTime after);
    long countByUser(User user);

    // --- Super-admin console (platform engagement metrics) ---

    long countByStartTimeAfter(LocalDateTime after);

    /** Just the start times in range, for cheap workout time-series bucketing. */
    @Query("SELECT w.startTime FROM WorkoutSession w WHERE w.startTime >= :after")
    List<LocalDateTime> startTimesSince(@Param("after") LocalDateTime after);
}
