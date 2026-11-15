package com.fityaar.workout.importer;

import com.fityaar.workout.entity.Exercise;
import com.fityaar.workout.entity.ExerciseAlias;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class ExerciseMatcherTest {

    private static long ids = 1;

    private static Exercise ex(String name, Exercise.Equipment eq) {
        return Exercise.builder().id(ids++).name(name).equipment(eq).isCustom(false).build();
    }

    private final Exercise benchBb = ex("Barbell Bench Press - Medium Grip", Exercise.Equipment.BARBELL);
    private final Exercise benchDb = ex("Dumbbell Bench Press", Exercise.Equipment.DUMBBELL);
    private final Exercise hammer = ex("Hammer Curls", Exercise.Equipment.DUMBBELL);
    private final Exercise seatedDbPress = ex("Seated Dumbbell Press", Exercise.Equipment.DUMBBELL);
    private final Exercise plank = ex("Plank", Exercise.Equipment.NO_EQUIPMENT);

    private final ExerciseMatcher matcher = new ExerciseMatcher(
            List.of(benchBb, benchDb, hammer, seatedDbPress, plank),
            List.of(ExerciseAlias.builder().aliasKey(ExerciseMatcher.normalize("Bench Press (Barbell)"))
                    .exercise(benchBb).build()));

    @Test
    void aliasWins() {
        var m = matcher.match("Bench Press (Barbell)").orElseThrow();
        assertSame(benchBb, m.exercise());
        assertEquals(ExerciseMatcher.Method.ALIAS, m.method());
    }

    @Test
    void reordersEquipmentSuffix() {
        var m = matcher.match("Bench Press (Dumbbell)").orElseThrow();
        assertSame(benchDb, m.exercise());
        assertEquals(ExerciseMatcher.Method.EXACT, m.method());
    }

    @Test
    void exactIgnoresCaseAndPunctuation() {
        assertSame(plank, matcher.match("PLANK").orElseThrow().exercise());
    }

    @Test
    void fuzzyRespectsEquipment() {
        assertSame(seatedDbPress, matcher.match("Seated Shoulder Press (Dumbbell)").orElseThrow().exercise());
        assertTrue(matcher.match("Seated Shoulder Press (Barbell)").isEmpty());
    }

    @Test
    void unknownStaysUnmatched() {
        assertTrue(matcher.match("Zercher Carry").isEmpty());
    }

    @Test
    void customOverridesCatalogWithSameName() {
        Exercise mine = Exercise.builder().id(999L).name("Plank").isCustom(true).build();
        var m = new ExerciseMatcher(List.of(plank, mine), List.of()).match("plank").orElseThrow();
        assertSame(mine, m.exercise());
    }

    @Test
    void equipmentFromSuffix() {
        assertEquals(Exercise.Equipment.CABLE, ExerciseMatcher.equipmentOf("Triceps Pushdown (Cable - Rope)"));
        assertNull(ExerciseMatcher.equipmentOf("Plank"));
    }

    @Test
    void fuzzyRejectsDifferentVariant() {
        Exercise squat = ex("Barbell Squat", Exercise.Equipment.BARBELL);
        Exercise tbar = ex("Lying T-Bar Row", Exercise.Equipment.MACHINE);
        Exercise oneArm = ex("Dumbbell One-Arm Triceps Extension", Exercise.Equipment.DUMBBELL);
        var m = new ExerciseMatcher(List.of(squat, tbar, oneArm), List.of());
        assertTrue(m.match("Sumo Squat (Barbell)").isEmpty());
        assertTrue(m.match("Pause Squat (Barbell)").isEmpty());
        assertTrue(m.match("T Bar Row").isEmpty());
        assertSame(oneArm, m.match("Single Arm Tricep Extension (Dumbbell)").orElseThrow().exercise());
    }
}
