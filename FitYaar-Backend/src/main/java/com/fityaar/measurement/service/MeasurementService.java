package com.fityaar.measurement.service;

import com.fityaar.exception.ResourceNotFoundException;
import com.fityaar.measurement.dto.MeasurementRequest;
import com.fityaar.measurement.dto.MeasurementResponse;
import com.fityaar.measurement.entity.BodyMeasurement;
import com.fityaar.measurement.repository.BodyMeasurementRepository;
import com.fityaar.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MeasurementService {

    private final BodyMeasurementRepository repo;

    public List<MeasurementResponse> list(User user) {
        return repo.findByUserOrderByMeasuredOnAsc(user).stream()
                .map(MeasurementResponse::from)
                .toList();
    }

    /** One entry per day: updates the existing row for that date or creates it. */
    @Transactional
    public MeasurementResponse upsert(User user, MeasurementRequest req) {
        LocalDate date = req.getDate() != null ? req.getDate() : LocalDate.now();
        BodyMeasurement m = repo.findByUserAndMeasuredOn(user, date)
                .orElseGet(() -> BodyMeasurement.builder()
                        .user(user).measuredOn(date).build());
        m.setWeightKg(req.getWeightKg());
        m.setWaistCm(req.getWaistCm());
        m.setBodyFatPct(req.getBodyFatPct());
        return MeasurementResponse.from(repo.save(m));
    }

    @Transactional
    public void delete(User user, Long id) {
        BodyMeasurement m = repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Measurement not found"));
        if (!m.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("Not your measurement");
        }
        repo.delete(m);
    }
}
