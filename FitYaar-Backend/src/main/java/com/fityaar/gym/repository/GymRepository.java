package com.fityaar.gym.repository;

import com.fityaar.gym.entity.Gym;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface GymRepository extends JpaRepository<Gym, Long> {
    Optional<Gym> findByJoinCode(String joinCode);
    Optional<Gym> findByOwnerCode(String ownerCode);
}
