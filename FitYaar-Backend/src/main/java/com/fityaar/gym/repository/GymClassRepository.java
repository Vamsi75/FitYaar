package com.fityaar.gym.repository;

import com.fityaar.gym.entity.Gym;
import com.fityaar.gym.entity.GymClass;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface GymClassRepository extends JpaRepository<GymClass, Long> {
    List<GymClass> findByGymOrderByCreatedAtDesc(Gym gym);
}
