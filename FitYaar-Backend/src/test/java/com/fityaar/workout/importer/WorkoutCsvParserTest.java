package com.fityaar.workout.importer;

import com.fityaar.workout.entity.SetEntry;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class WorkoutCsvParserTest {

    private static final String HEVY = """
            "title","start_time","end_time","description","exercise_title","superset_id","exercise_notes","set_index","set_type","weight_kg","reps","distance_km","duration_seconds","rpe"
            "Push Day","26 Jan 2024, 18:30","26 Jan 2024, 19:35","Felt strong","Bench Press (Barbell)",,"Pause reps",0,"warmup",40,10,,,
            "Push Day","26 Jan 2024, 18:30","26 Jan 2024, 19:35","Felt strong","Bench Press (Barbell)",,"Pause reps",1,"normal",80,5,,,8.5
            "Push Day","26 Jan 2024, 18:30","26 Jan 2024, 19:35","Felt strong","Plank",,,0,"normal",,,,60,
            "Legs","24 Jan 2024, 07:00","24 Jan 2024, 08:00",,"Running",,,0,"normal",,,2.5,900,
            """;

    @Test
    void parsesHevyExport() {
        var r = WorkoutCsvParser.parse(HEVY, WorkoutCsvParser.WeightUnit.KG);
        assertEquals(WorkoutCsvParser.Format.HEVY, r.format());
        assertEquals(2, r.workouts().size());

        ParsedWorkout legs = r.workouts().get(0); // sorted oldest first
        assertEquals("Legs", legs.title());
        assertEquals(2500.0, legs.exercises().get(0).sets().get(0).distanceMeters());

        ParsedWorkout push = r.workouts().get(1);
        assertEquals(LocalDateTime.of(2024, 1, 26, 18, 30), push.start());
        assertEquals(LocalDateTime.of(2024, 1, 26, 19, 35), push.end());
        assertEquals("Felt strong", push.notes());
        assertEquals(2, push.exercises().size());

        var bench = push.exercises().get(0);
        assertEquals("Bench Press (Barbell)", bench.name());
        assertEquals("Pause reps", bench.notes());
        assertEquals(SetEntry.SetType.WARMUP, bench.sets().get(0).type());
        assertEquals(80.0, bench.sets().get(1).weightKg());
        assertEquals(9, bench.sets().get(1).rpe()); // 8.5 rounds
        assertEquals(60, push.exercises().get(1).sets().get(0).durationSeconds());
    }

    @Test
    void convertsHevyPounds() {
        String csv = """
                title,start_time,end_time,description,exercise_title,superset_id,exercise_notes,set_index,set_type,weight_lbs,reps,distance_miles,duration_seconds,rpe
                A,"1 Feb 2024, 10:00",,,Squat (Barbell),,,0,normal,225,5,,,
                """;
        var set = WorkoutCsvParser.parse(csv, WorkoutCsvParser.WeightUnit.KG)
                .workouts().get(0).exercises().get(0).sets().get(0);
        assertEquals(102.06, set.weightKg(), 0.001);
    }

    @Test
    void parsesStrongExportWithUnitsAndRestRows() {
        String csv = """
                Date;Workout Name;Duration;Exercise Name;Set Order;Weight;Reps;Distance;Seconds;Notes;Workout Notes;RPE
                2023-05-01 08:00:00;Morning;1h 5m;Deadlift (Barbell);W;60;5;0;0;;Back day;
                2023-05-01 08:00:00;Morning;1h 5m;Deadlift (Barbell);1;140;3;0;0;belt;Back day;9
                2023-05-01 08:00:00;Morning;1h 5m;Deadlift (Barbell);Rest Timer;;;;90;;Back day;
                2023-05-01 08:00:00;Morning;1h 5m;Pull Up;1;0;10;0;0;;Back day;
                """;
        var r = WorkoutCsvParser.parse(csv, WorkoutCsvParser.WeightUnit.LBS);
        assertEquals(WorkoutCsvParser.Format.STRONG, r.format());
        ParsedWorkout w = r.workouts().get(0);
        assertEquals(LocalDateTime.of(2023, 5, 1, 9, 5), w.end());
        assertEquals("Back day", w.notes());
        var dl = w.exercises().get(0);
        assertEquals(2, dl.sets().size()); // rest-timer row ignored
        assertEquals(SetEntry.SetType.WARMUP, dl.sets().get(0).type());
        assertEquals(63.5, dl.sets().get(1).weightKg(), 0.01); // 140 lb
        assertEquals("belt", dl.notes());
    }

    @Test
    void parsesStrongVariantWithUnitColumns() {
        String csv = """
                Date,Workout Name,Exercise Name,Set Order,Weight,Weight Unit,Reps,RPE,Distance,Distance Unit,Seconds,Notes,Workout Notes,Workout Duration
                2023-06-02 18:00:00,Evening,Bench Press (Dumbbell),1,30,kg,10,,,,,,,45m
                2023-06-02 18:00:00,Evening,Treadmill,1,,,,,1,mi,600,,,45m
                """;
        var w = WorkoutCsvParser.parse(csv, WorkoutCsvParser.WeightUnit.LBS).workouts().get(0);
        assertEquals(30.0, w.exercises().get(0).sets().get(0).weightKg()); // unit column wins
        assertEquals(1609.34, w.exercises().get(1).sets().get(0).distanceMeters(), 0.01);
        assertEquals(LocalDateTime.of(2023, 6, 2, 18, 45), w.end());
    }

    @Test
    void skipsBadRowsWithWarning() {
        String csv = """
                Date,Workout Name,Exercise Name,Set Order,Weight,Reps
                not-a-date,X,Squat,1,100,5
                2023-06-02 18:00:00,Y,Squat,1,100,5
                """;
        var r = WorkoutCsvParser.parse(csv, WorkoutCsvParser.WeightUnit.KG);
        assertEquals(1, r.workouts().size());
        assertEquals(1, r.rowsSkipped());
        assertTrue(r.warnings().get(0).contains("Row 2"));
    }

    @Test
    void rejectsUnknownFile() {
        assertThrows(IllegalArgumentException.class,
                () -> WorkoutCsvParser.parse("a,b,c\n1,2,3\n", WorkoutCsvParser.WeightUnit.KG));
    }

    @Test
    void csvReaderHandlesQuotesAndNewlines() {
        List<List<String>> rows = CsvReader.parse("a,b\n\"x, \"\"y\"\"\",\"multi\nline\"\n");
        assertEquals(List.of("x, \"y\"", "multi\nline"), rows.get(1));
    }

    @Test
    void durations() {
        assertEquals(3900, WorkoutCsvParser.durationSeconds("1h 5m"));
        assertEquals(2700, WorkoutCsvParser.durationSeconds("45m"));
        assertEquals(120, WorkoutCsvParser.durationSeconds("120"));
        assertNull(WorkoutCsvParser.durationSeconds("abc"));
    }

    @Test
    void hevyAppDateFormats() {
        LocalDateTime expected = LocalDateTime.of(2026, 10, 21, 20, 43);
        assertEquals(expected, WorkoutCsvParser.tryDate("Oct 21, 2026 at 8:43 PM"));
        assertEquals(expected, WorkoutCsvParser.tryDate("Oct 21, 2026 at 8:43\u202FPM"));
        assertEquals(expected, WorkoutCsvParser.tryDate("21 Oct 2026 at 20:43"));
    }
}
