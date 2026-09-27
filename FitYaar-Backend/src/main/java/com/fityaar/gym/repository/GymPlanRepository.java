package com.fityaar.gym.repository;

import com.fityaar.gym.entity.Gym;
import com.fityaar.gym.entity.GymPlan;
import com.fityaar.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface GymPlanRepository extends JpaRepository<GymPlan, Long> {
    Optional<GymPlan> findTopByGymOrderByPlanDateDescCreatedAtDesc(Gym gym);
    Optional<GymPlan> findTopByGymAndClientOrderByPlanDateDescCreatedAtDesc(Gym gym, User client);
}
