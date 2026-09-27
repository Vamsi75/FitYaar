package com.fityaar.gym.repository;

import com.fityaar.gym.entity.Gym;
import com.fityaar.gym.entity.GymMembership;
import com.fityaar.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GymMembershipRepository extends JpaRepository<GymMembership, Long> {
    Optional<GymMembership> findByUserAndGym(User user, Gym gym);
    List<GymMembership> findByUser(User user);
    List<GymMembership> findByGym(Gym gym);
    List<GymMembership> findByGymAndStatus(Gym gym, GymMembership.Status status);
    long countByStatus(GymMembership.Status status);
    long countByStatusAndRole(GymMembership.Status status, GymMembership.Role role);
}
