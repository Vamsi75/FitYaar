package com.fityaar.measurement.dto;

import lombok.Data;

import java.time.LocalDate;

/** Upsert one day's body metrics. [date] defaults to today when omitted. */
@Data
public class MeasurementRequest {
    private LocalDate date;
    private Double weightKg;
    private Double waistCm;
    private Double bodyFatPct;
}
