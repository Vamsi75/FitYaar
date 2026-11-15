package com.fityaar.workout.importer;

import java.util.ArrayList;
import java.util.List;

/**
 * Minimal RFC-4180 CSV reader: quoted fields, escaped quotes ("") and newlines inside quotes.
 * Detects ',' vs ';' from the header line (Strong uses ';' in some locales).
 */
final class CsvReader {

    private CsvReader() {
    }

    static List<List<String>> parse(String text) {
        if (text == null || text.isEmpty()) return List.of();
        if (text.charAt(0) == '﻿') text = text.substring(1); // UTF-8 BOM
        char delimiter = detectDelimiter(text);

        List<List<String>> rows = new ArrayList<>();
        List<String> row = new ArrayList<>();
        StringBuilder field = new StringBuilder();
        boolean inQuotes = false;
        int n = text.length();

        for (int i = 0; i < n; i++) {
            char c = text.charAt(i);
            if (inQuotes) {
                if (c == '"') {
                    if (i + 1 < n && text.charAt(i + 1) == '"') {
                        field.append('"');
                        i++;
                    } else {
                        inQuotes = false;
                    }
                } else {
                    field.append(c);
                }
            } else if (c == '"') {
                inQuotes = true;
            } else if (c == delimiter) {
                row.add(field.toString());
                field.setLength(0);
            } else if (c == '\n' || c == '\r') {
                if (c == '\r' && i + 1 < n && text.charAt(i + 1) == '\n') i++;
                row.add(field.toString());
                field.setLength(0);
                addIfNotBlank(rows, row);
                row = new ArrayList<>();
            } else {
                field.append(c);
            }
        }
        row.add(field.toString());
        addIfNotBlank(rows, row);
        return rows;
    }

    private static void addIfNotBlank(List<List<String>> rows, List<String> row) {
        for (String f : row) {
            if (!f.isBlank()) {
                rows.add(row);
                return;
            }
        }
    }

    /** Whichever of ',' / ';' appears more often (outside quotes) on the first line wins. */
    private static char detectDelimiter(String text) {
        int commas = 0, semis = 0;
        boolean inQuotes = false;
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            if (c == '"') inQuotes = !inQuotes;
            else if (!inQuotes && (c == '\n' || c == '\r')) break;
            else if (!inQuotes && c == ',') commas++;
            else if (!inQuotes && c == ';') semis++;
        }
        return semis > commas ? ';' : ',';
    }
}
