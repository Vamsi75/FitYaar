package com.fityaar.nutrition.repository;

import com.fityaar.nutrition.entity.WaterEntry;
import com.fityaar.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface WaterEntryRepository extends JpaRepository<WaterEntry, Long> {
    List<WaterEntry> findByUserAndDate(User user, LocalDate date);
}
