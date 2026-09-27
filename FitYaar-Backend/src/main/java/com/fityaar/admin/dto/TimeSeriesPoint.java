package com.fityaar.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.time.LocalDate;

/** One daily bucket for a dashboard trend line. */
@Data
@AllArgsConstructor
public class TimeSeriesPoint {
    private LocalDate date;
    private long count;
}
