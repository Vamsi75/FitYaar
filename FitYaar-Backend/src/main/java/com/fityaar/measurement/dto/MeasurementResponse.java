package com.fityaar.measurement.dto;

import com.fityaar.measurement.entity.BodyMeasurement;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;

@Data
@Builder
public class MeasurementResponse {
    private Long id;
    private LocalDate date;
    private Double weightKg;
    private Double waistCm;
    private Double bodyFatPct;

    public static MeasurementResponse from(BodyMeasurement m) {
        return MeasurementResponse.builder()
                .id(m.getId())
                .date(m.getMeasuredOn())
                .weightKg(m.getWeightKg())
                .waistCm(m.getWaistCm())
                .bodyFatPct(m.getBodyFatPct())
                .build();
    }
}
