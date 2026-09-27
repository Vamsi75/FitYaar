package com.fityaar.gym.repository;

import com.fityaar.gym.entity.Gym;
import com.fityaar.gym.entity.GymEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GymEventRepository extends JpaRepository<GymEvent, Long> {
    List<GymEvent> findByGymOrderByCreatedAtDesc(Gym gym);
}
