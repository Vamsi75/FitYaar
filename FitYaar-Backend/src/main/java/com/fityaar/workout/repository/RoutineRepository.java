package com.fityaar.workout.repository;

import com.fityaar.user.entity.User;
import com.fityaar.workout.entity.Routine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoutineRepository extends JpaRepository<Routine, Long> {
    List<Routine> findByUser(User user);
    List<Routine> findByIsTemplateTrue();

    @org.springframework.data.jpa.repository.Query("SELECT r FROM Routine r WHERE r.isTemplate = true OR r.user = :user")
    List<Routine> findTemplatesAndUserRoutines(User user);
}
