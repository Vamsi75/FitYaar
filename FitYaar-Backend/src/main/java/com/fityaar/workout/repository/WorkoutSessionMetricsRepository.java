package com.fityaar.workout.repository;

import com.fityaar.workout.entity.WorkoutSessionMetrics;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

public interface WorkoutSessionMetricsRepository extends JpaRepository<WorkoutSessionMetrics, Long> {
    List<WorkoutSessionMetrics> findBySessionIdIn(Collection<Long> sessionIds);
}
