package com.fityaar.measurement.controller;

import com.fityaar.measurement.dto.MeasurementRequest;
import com.fityaar.measurement.dto.MeasurementResponse;
import com.fityaar.measurement.service.MeasurementService;
import com.fityaar.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/measurements")
@RequiredArgsConstructor
public class MeasurementController {

    private final MeasurementService service;

    @GetMapping
    public ResponseEntity<List<MeasurementResponse>> list(
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(service.list(principal.getUser()));
    }

    @PostMapping
    public ResponseEntity<MeasurementResponse> upsert(
            @RequestBody MeasurementRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(service.upsert(principal.getUser(), request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        service.delete(principal.getUser(), id);
        return ResponseEntity.noContent().build();
    }
}
