package com.fityaar.gym.repository;

import com.fityaar.gym.entity.GymPlan;
import com.fityaar.gym.entity.GymPlanItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface GymPlanItemRepository extends JpaRepository<GymPlanItem, Long> {
    List<GymPlanItem> findByPlanOrderByOrderIndex(GymPlan plan);
}
