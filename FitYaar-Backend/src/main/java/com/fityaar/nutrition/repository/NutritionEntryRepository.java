package com.fityaar.nutrition.repository;

import com.fityaar.nutrition.entity.NutritionEntry;
import com.fityaar.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface NutritionEntryRepository extends JpaRepository<NutritionEntry, Long> {
    List<NutritionEntry> findByUserAndDate(User user, LocalDate date);
}
