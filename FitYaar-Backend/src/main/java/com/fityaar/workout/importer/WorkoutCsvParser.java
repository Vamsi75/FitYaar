package com.fityaar.workout.importer;

import com.fityaar.workout.entity.SetEntry;
import com.fityaar.workout.importer.ParsedWorkout.ParsedExercise;
import com.fityaar.workout.importer.ParsedWorkout.ParsedSet;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.format.DateTimeParseException;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Parses workout-history CSV exports from Hevy and Strong into {@link ParsedWorkout}s.
 *
 * <p>Both apps write one row per set. Headers are matched by normalized name (lower-case,
 * non-alphanumerics → '_'), so "Weight (kg)", "weight_kg" and "Weight_KG" are the same column.
 * Known variants:
 * <ul>
 *   <li><b>Hevy</b>: title, start_time, end_time, description, exercise_title, superset_id,
 *       exercise_notes, set_index, set_type, weight_kg|weight_lbs, reps,
 *       distance_km|distance_miles, duration_seconds, rpe</li>
 *   <li><b>Strong</b>: Date, Workout Name, Duration, Exercise Name, Set Order, Weight
 *       [, Weight Unit], Reps, Distance [, Distance Unit], Seconds, Notes, Workout Notes, RPE
 *       (also the "Weight (kg) / Distance (m) / Duration (s)" variant)</li>
 * </ul>
 */
public final class WorkoutCsvParser {

    public enum Format { HEVY, STRONG }

    public enum WeightUnit { KG, LBS }

    public record Result(Format format, List<ParsedWorkout> workouts, List<String> warnings, int rowsSkipped) {
    }

    static final int MAX_ROWS = 300_000;
    private static final int MAX_WARNINGS = 50;
    private static final double LB_TO_KG = 0.45359237;
    private static final double MILE_TO_M = 1609.344;

    private static final List<DateTimeFormatter> DATE_FORMATS = List.of(
            fmt("d MMM yyyy, HH:mm"),          // Hevy: "26 Jan 2024, 18:30"
            fmt("d MMM yyyy, H:mm"),
            fmt("d MMM yyyy HH:mm"),
            fmt("MMM d, yyyy, h:mm a"),        // Hevy (US locale): "Jan 26, 2024, 6:30 PM"
            fmt("MMM d, yyyy h:mm a"),
            fmt("MMM d, yyyy 'at' h:mm a"),     // Hevy app export: "Oct 21, 2026 at 8:43 PM"
            fmt("d MMM yyyy 'at' HH:mm"),       // Hevy app export, 24h locales: "21 Oct 2026 at 20:43"
            fmt("d MMM yyyy 'at' h:mm a"),
            fmt("yyyy-MM-dd HH:mm:ss"),        // Strong: "2024-01-26 18:30:00"
            fmt("yyyy-MM-dd HH:mm"),
            fmt("yyyy-MM-dd'T'HH:mm:ss"),
            fmt("yyyy-MM-dd'T'HH:mm"),
            fmt("yyyy/MM/dd HH:mm:ss"),
            fmt("yyyy/MM/dd HH:mm"));

    private static final Pattern DURATION_PART = Pattern.compile("(\\d+)\\s*([hms])");

    private WorkoutCsvParser() {
    }

    public static Result parse(String csv, WeightUnit defaultWeightUnit) {
        List<List<String>> rows = CsvReader.parse(csv);
        if (rows.isEmpty()) throw new IllegalArgumentException("The file is empty.");
        if (rows.size() > MAX_ROWS) {
            throw new IllegalArgumentException("File too large: at most " + MAX_ROWS + " sets per import.");
        }

        Header h = new Header(rows.get(0));
        Format format;
        if (h.has("exercise_title") && h.has("start_time")) format = Format.HEVY;
        else if (h.has("exercise_name") && h.has("date")) format = Format.STRONG;
        else throw new IllegalArgumentException(
                    "Unrecognised file. Upload the workout CSV exported from Hevy or Strong.");

        Parser p = new Parser(h, format, defaultWeightUnit == null ? WeightUnit.KG : defaultWeightUnit);
        for (int i = 1; i < rows.size(); i++) {
            p.row(i + 1, rows.get(i));
        }
        List<ParsedWorkout> workouts = new ArrayList<>(p.workouts.values());
        workouts.removeIf(w -> w.exercises.isEmpty());
        workouts.sort(Comparator.comparing(ParsedWorkout::start));
        return new Result(format, workouts, p.warnings, p.skipped);
    }

    // ---------------------------------------------------------------------------------------

    private static final class Parser {
        final Header h;
        final Format format;
        final WeightUnit defaultUnit;
        final Map<String, ParsedWorkout> workouts = new LinkedHashMap<>();
        final List<String> warnings = new ArrayList<>();
        int skipped = 0;

        Parser(Header h, Format format, WeightUnit defaultUnit) {
            this.h = h;
            this.format = format;
            this.defaultUnit = defaultUnit;
        }

        void row(int line, List<String> r) {
            try {
                if (format == Format.HEVY) hevy(r);
                else strong(r);
            } catch (RowException e) {
                skipped++;
                warn("Row " + line + ": " + e.getMessage());
            }
        }

        void hevy(List<String> r) {
            String title = h.get(r, "title");
            String startRaw = h.get(r, "start_time");
            LocalDateTime start = date(startRaw);
            String exName = h.get(r, "exercise_title");
            if (exName == null) throw new RowException("missing exercise name");

            ParsedWorkout w = workouts.computeIfAbsent(title + "|" + startRaw,
                    k -> new ParsedWorkout(orDefault(title, "Imported workout"), start));
            if (w.end == null) {
                String endRaw = h.get(r, "end_time");
                if (endRaw != null) w.end = tryDate(endRaw);
            }
            if (w.notes == null) w.notes = h.get(r, "description");

            ParsedExercise ex = exercise(w, exName);
            if (ex.notes == null) ex.notes = h.get(r, "exercise_notes");

            Double weight = h.has("weight_lbs") ? lbs(num(h.get(r, "weight_lbs")))
                    : num(h.get(r, "weight_kg"));
            Double distance = h.has("distance_miles") ? miles(num(h.get(r, "distance_miles")))
                    : km(num(h.get(r, "distance_km")));
            addSet(ex, new ParsedSet(
                    hevySetType(h.get(r, "set_type")),
                    weight,
                    intOrNull(num(h.get(r, "reps"))),
                    intOrNull(num(h.get(r, "rpe"))),
                    intOrNull(num(h.get(r, "duration_seconds"))),
                    distance));
        }

        void strong(List<String> r) {
            String setOrder = h.get(r, "set_order");
            if (setOrder != null && setOrder.toLowerCase(Locale.ROOT).contains("rest")) {
                return; // "Rest Timer" rows in newer Strong exports aren't sets
            }
            String dateRaw = h.get(r, "date");
            LocalDateTime start = date(dateRaw);
            String title = h.get(r, "workout_name");
            String exName = h.get(r, "exercise_name");
            if (exName == null) throw new RowException("missing exercise name");

            ParsedWorkout w = workouts.computeIfAbsent(dateRaw + "|" + title,
                    k -> new ParsedWorkout(orDefault(title, "Imported workout"), start));
            if (w.end == null) {
                Integer secs = durationSeconds(h.first(r, "workout_duration", "duration"));
                if (secs != null && secs > 0) w.end = start.plusSeconds(secs);
            }
            if (w.notes == null) w.notes = h.get(r, "workout_notes");

            ParsedExercise ex = exercise(w, exName);
            String setNote = h.get(r, "notes");
            if (setNote != null) {
                ex.notes = ex.notes == null ? setNote
                        : (ex.notes.contains(setNote) ? ex.notes : ex.notes + " · " + setNote);
            }

            addSet(ex, new ParsedSet(
                    strongSetType(setOrder),
                    strongWeight(r),
                    intOrNull(num(h.get(r, "reps"))),
                    intOrNull(num(h.get(r, "rpe"))),
                    intOrNull(num(h.first(r, "seconds", "duration_s", "duration_seconds"))),
                    strongDistance(r)));
        }

        Double strongWeight(List<String> r) {
            if (h.has("weight_kg")) return num(h.get(r, "weight_kg"));
            if (h.has("weight_lbs")) return lbs(num(h.get(r, "weight_lbs")));
            if (h.has("weight_lb")) return lbs(num(h.get(r, "weight_lb")));
            Double w = num(h.get(r, "weight"));
            String unit = h.get(r, "weight_unit");
            boolean pounds = unit != null ? unit.toLowerCase(Locale.ROOT).startsWith("lb")
                    : defaultUnit == WeightUnit.LBS;
            return pounds ? lbs(w) : w;
        }

        Double strongDistance(List<String> r) {
            if (h.has("distance_m")) return num(h.get(r, "distance_m"));
            if (h.has("distance_km")) return km(num(h.get(r, "distance_km")));
            if (h.has("distance_miles")) return miles(num(h.get(r, "distance_miles")));
            if (h.has("distance_mi")) return miles(num(h.get(r, "distance_mi")));
            Double d = num(h.get(r, "distance"));
            if (d == null) return null;
            String unit = h.get(r, "distance_unit");
            if (unit == null) {
                // Strong writes distance in the user's unit system; follow the weight unit choice.
                return defaultUnit == WeightUnit.LBS ? miles(d) : km(d);
            }
            return switch (unit.toLowerCase(Locale.ROOT)) {
                case "m", "meter", "meters", "metre", "metres" -> d;
                case "mi", "mile", "miles" -> miles(d);
                case "ft", "feet" -> d * 0.3048;
                case "yd", "yards" -> d * 0.9144;
                default -> km(d);
            };
        }

        ParsedExercise exercise(ParsedWorkout w, String name) {
            // Consecutive rows of the same exercise are one block; a repeat later in the
            // workout becomes its own block (matches how both apps order their rows).
            if (!w.exercises.isEmpty()) {
                ParsedExercise last = w.exercises.get(w.exercises.size() - 1);
                if (last.name.equals(name)) return last;
            }
            ParsedExercise ex = new ParsedExercise(name);
            w.exercises.add(ex);
            return ex;
        }

        void addSet(ParsedExercise ex, ParsedSet set) {
            if (set.isEmpty()) {
                skipped++;
                return;
            }
            ex.sets.add(set);
        }

        void warn(String msg) {
            if (warnings.size() < MAX_WARNINGS) warnings.add(msg);
        }
    }

    // ---------------------------------------------------------------------------------------

    private static final class Header {
        final Map<String, Integer> idx = new HashMap<>();

        Header(List<String> cols) {
            for (int i = 0; i < cols.size(); i++) {
                idx.putIfAbsent(norm(cols.get(i)), i);
            }
        }

        boolean has(String key) {
            return idx.containsKey(key);
        }

        /** Trimmed value, or null when the column is missing / blank. */
        String get(List<String> row, String key) {
            Integer i = idx.get(key);
            if (i == null || i >= row.size()) return null;
            String v = row.get(i).trim();
            return v.isEmpty() ? null : v;
        }

        String first(List<String> row, String... keys) {
            for (String k : keys) {
                if (has(k)) return get(row, k);
            }
            return null;
        }

        static String norm(String col) {
            return col.trim().toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+", "_")
                    .replaceAll("^_+|_+$", "");
        }
    }

    private static final class RowException extends RuntimeException {
        RowException(String msg) {
            super(msg);
        }
    }

    // ---- value helpers ----

    private static DateTimeFormatter fmt(String pattern) {
        return new DateTimeFormatterBuilder().parseCaseInsensitive().appendPattern(pattern)
                .toFormatter(Locale.ENGLISH);
    }

    static LocalDateTime date(String raw) {
        if (raw == null) throw new RowException("missing date");
        LocalDateTime d = tryDate(raw);
        if (d == null) throw new RowException("unrecognised date '" + raw + "'");
        return d;
    }

    static LocalDateTime tryDate(String raw) {
        if (raw == null) return null;
        // Exports from iOS can use non-breaking / narrow no-break spaces before AM/PM.
        String s = raw.replace('\u00A0', ' ').replace('\u202F', ' ').trim().replaceAll("\\s+", " ");
        for (DateTimeFormatter f : DATE_FORMATS) {
            try {
                return LocalDateTime.parse(s, f);
            } catch (DateTimeParseException ignored) {
                // try the next pattern
            }
        }
        return null;
    }

    /** "1h 5m", "45m", "30s", "1h", or a bare number of seconds. */
    static Integer durationSeconds(String raw) {
        if (raw == null) return null;
        String s = raw.trim().toLowerCase(Locale.ROOT);
        if (s.matches("\\d+")) return Integer.parseInt(s);
        Matcher m = DURATION_PART.matcher(s);
        int total = 0;
        boolean found = false;
        while (m.find()) {
            found = true;
            int v = Integer.parseInt(m.group(1));
            total += switch (m.group(2)) {
                case "h" -> v * 3600;
                case "m" -> v * 60;
                default -> v;
            };
        }
        return found ? total : null;
    }

    static Double num(String raw) {
        if (raw == null) return null;
        String s = raw.trim();
        if (s.indexOf('.') < 0 && s.indexOf(',') >= 0) s = s.replace(',', '.'); // "62,5" (EU locales)
        try {
            double d = Double.parseDouble(s);
            return Double.isFinite(d) ? d : null;
        } catch (NumberFormatException e) {
            throw new RowException("not a number: '" + raw + "'");
        }
    }

    private static Integer intOrNull(Double d) {
        return d == null ? null : (int) Math.round(d);
    }

    private static Double lbs(Double v) {
        return v == null ? null : round2(v * LB_TO_KG);
    }

    private static Double km(Double v) {
        return v == null ? null : round2(v * 1000);
    }

    private static Double miles(Double v) {
        return v == null ? null : round2(v * MILE_TO_M);
    }

    private static double round2(double v) {
        return Math.round(v * 100.0) / 100.0;
    }

    private static String orDefault(String v, String def) {
        return v == null ? def : v;
    }

    private static SetEntry.SetType hevySetType(String raw) {
        if (raw == null) return SetEntry.SetType.NORMAL;
        return switch (raw.toLowerCase(Locale.ROOT)) {
            case "warmup", "warm_up", "warm-up" -> SetEntry.SetType.WARMUP;
            case "dropset", "drop_set", "drop" -> SetEntry.SetType.DROPSET;
            case "failure" -> SetEntry.SetType.FAILURE;
            default -> SetEntry.SetType.NORMAL;
        };
    }

    private static SetEntry.SetType strongSetType(String raw) {
        if (raw == null) return SetEntry.SetType.NORMAL;
        return switch (raw.trim().toUpperCase(Locale.ROOT)) {
            case "W" -> SetEntry.SetType.WARMUP;
            case "D" -> SetEntry.SetType.DROPSET;
            case "F" -> SetEntry.SetType.FAILURE;
            default -> SetEntry.SetType.NORMAL;
        };
    }
}
