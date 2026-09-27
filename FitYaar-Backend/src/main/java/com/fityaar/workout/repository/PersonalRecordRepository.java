package com.fityaar.workout.repository;

import com.fityaar.user.entity.User;
import com.fityaar.workout.entity.Exercise;
import com.fityaar.workout.entity.PersonalRecord;
import com.fityaar.workout.entity.WorkoutSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PersonalRecordRepository extends JpaRepository<PersonalRecord, Long> {
    List<PersonalRecord> findByUser(User user);
    Optional<PersonalRecord> findByUserAndExercise(User user, Exercise exercise);
    List<PersonalRecord> findByWorkoutSession(WorkoutSession session);
}
