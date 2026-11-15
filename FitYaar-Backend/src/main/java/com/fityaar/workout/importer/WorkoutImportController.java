package com.fityaar.workout.importer;

import com.fityaar.security.UserPrincipal;
import com.fityaar.workout.dto.WorkoutImportResult;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

/** {@code POST /api/workout/import} — upload a Hevy or Strong CSV export. */
@RestController
@RequestMapping("/api/workout/import")
@RequiredArgsConstructor
public class WorkoutImportController {

    private final WorkoutImportService importService;

    /**
     * @param file       the CSV (multipart field {@code file})
     * @param dryRun     true → parse + match only, nothing is saved (preview)
     * @param weightUnit KG | LBS — only used when the file doesn't say (Strong's plain "Weight")
     */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<WorkoutImportResult> importCsv(
            @RequestParam("file") MultipartFile file,
            @RequestParam(name = "dryRun", defaultValue = "false") boolean dryRun,
            @RequestParam(name = "weightUnit", defaultValue = "KG") String weightUnit,
            @AuthenticationPrincipal UserPrincipal principal) throws IOException {
        if (file.isEmpty()) throw new IllegalArgumentException("The file is empty.");
        WorkoutCsvParser.WeightUnit unit;
        try {
            unit = WorkoutCsvParser.WeightUnit.valueOf(weightUnit.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("weightUnit must be KG or LBS");
        }
        String csv = new String(file.getBytes(), StandardCharsets.UTF_8);
        return ResponseEntity.ok(importService.importCsv(principal.getUser(), csv, unit, dryRun));
    }
}
