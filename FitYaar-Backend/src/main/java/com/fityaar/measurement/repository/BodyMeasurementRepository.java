package com.fityaar.measurement.repository;

import com.fityaar.measurement.entity.BodyMeasurement;
import com.fityaar.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface BodyMeasurementRepository extends JpaRepository<BodyMeasurement, Long> {

    List<BodyMeasurement> findByUserOrderByMeasuredOnAsc(User user);

    Optional<BodyMeasurement> findByUserAndMeasuredOn(User user, LocalDate measuredOn);
}
