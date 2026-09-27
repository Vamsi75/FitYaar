package com.fityaar.gym.repository;

import com.fityaar.gym.entity.Gym;
import com.fityaar.gym.entity.GymCheckin;
import com.fityaar.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface GymCheckinRepository extends JpaRepository<GymCheckin, Long> {
    long countByGymAndCheckOutAtIsNull(Gym gym);
    Optional<GymCheckin> findByUserAndGymAndCheckOutAtIsNull(User user, Gym gym);
    List<GymCheckin> findByGymAndCheckOutAtIsNull(Gym gym);
    List<GymCheckin> findByUserAndCheckOutAtIsNull(User user);
    List<GymCheckin> findByGymAndCheckInAtAfter(Gym gym, LocalDateTime after);
}
