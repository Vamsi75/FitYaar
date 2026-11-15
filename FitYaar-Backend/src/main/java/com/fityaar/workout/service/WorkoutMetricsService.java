package com.fityaar.workout.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fityaar.exception.ResourceNotFoundException;
import com.fityaar.user.entity.User;
import com.fityaar.workout.dto.WorkoutMetricsDto;
import com.fityaar.workout.entity.WorkoutSession;
import com.fityaar.workout.entity.WorkoutSessionMetrics;
import com.fityaar.workout.repository.WorkoutSessionMetricsRepository;
import com.fityaar.workout.repository.WorkoutSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/** Stores / serves the wearable metrics (heart rate, zones, calories) attached to a session. */
@Service
@RequiredArgsConstructor
public class WorkoutMetricsService {

    private static final TypeReference<List<List<Integer>>> SAMPLES = new TypeReference<>() {
    };

    private final WorkoutSessionMetricsRepository metricsRepository;
    private final WorkoutSessionRepository sessionRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public WorkoutMetricsDto upsert(User user, Long sessionId, WorkoutMetricsDto dto) {
        requireOwned(user, sessionId);
        WorkoutSessionMetrics m = metricsRepository.findById(sessionId)
                .orElseGet(() -> WorkoutSessionMetrics.builder().sessionId(sessionId).build());
        m.setPlatform(dto.getPlatform() == null ? null : WorkoutSessionMetrics.Platform.valueOf(dto.getPlatform()));
        m.setSourceName(dto.getSourceName());
        m.setAvgHeartRate(dto.getAvgHeartRate());
        m.setMaxHeartRate(dto.getMaxHeartRate());
        m.setMinHeartRate(dto.getMinHeartRate());
        m.setActiveCalories(dto.getActiveCalories());
        m.setTotalCalories(dto.getTotalCalories());
        m.setMaxHrUsed(dto.getMaxHrUsed());
        List<Integer> z = dto.getZoneSeconds() == null ? List.of() : dto.getZoneSeconds();
        m.setZone1Seconds(zone(z, 0));
        m.setZone2Seconds(zone(z, 1));
        m.setZone3Seconds(zone(z, 2));
        m.setZone4Seconds(zone(z, 3));
        m.setZone5Seconds(zone(z, 4));
        m.setHeartRateSamples(writeSamples(dto.getHeartRateSamples()));
        return toDto(metricsRepository.save(m));
    }

    @Transactional
    public void delete(User user, Long sessionId) {
        requireOwned(user, sessionId);
        metricsRepository.findById(sessionId).ifPresent(metricsRepository::delete);
    }

    public Optional<WorkoutMetricsDto> forSession(Long sessionId) {
        return metricsRepository.findById(sessionId).map(this::toDto);
    }

    /** Batch lookup for history lists (avoids one query per session). */
    public Map<Long, WorkoutMetricsDto> forSessions(Collection<Long> sessionIds) {
        if (sessionIds.isEmpty()) return Map.of();
        return metricsRepository.findBySessionIdIn(sessionIds).stream()
                .collect(Collectors.toMap(WorkoutSessionMetrics::getSessionId, this::toDto));
    }

    private void requireOwned(User user, Long sessionId) {
        WorkoutSession s = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Workout not found: " + sessionId));
        if (s.getUser() == null || !s.getUser().getId().equals(user.getId())) {
            throw new ResourceNotFoundException("Workout not found: " + sessionId);
        }
    }

    private WorkoutMetricsDto toDto(WorkoutSessionMetrics m) {
        return WorkoutMetricsDto.builder()
                .platform(m.getPlatform() == null ? null : m.getPlatform().name())
                .sourceName(m.getSourceName())
                .avgHeartRate(m.getAvgHeartRate())
                .maxHeartRate(m.getMaxHeartRate())
                .minHeartRate(m.getMinHeartRate())
                .activeCalories(m.getActiveCalories())
                .totalCalories(m.getTotalCalories())
                .maxHrUsed(m.getMaxHrUsed())
                .zoneSeconds(Arrays.asList(m.getZone1Seconds(), m.getZone2Seconds(), m.getZone3Seconds(),
                        m.getZone4Seconds(), m.getZone5Seconds()))
                .heartRateSamples(readSamples(m.getHeartRateSamples()))
                .build();
    }

    private static Integer zone(List<Integer> z, int i) {
        return i < z.size() ? z.get(i) : null;
    }

    private String writeSamples(List<List<Integer>> samples) {
        if (samples == null || samples.isEmpty()) return null;
        try {
            return objectMapper.writeValueAsString(samples);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("Invalid heart-rate samples");
        }
    }

    private List<List<Integer>> readSamples(String json) {
        if (json == null || json.isBlank()) return null;
        try {
            return objectMapper.readValue(json, SAMPLES);
        } catch (JsonProcessingException e) {
            return null;
        }
    }
}
