package com.fityaar.workout.importer;

import com.fityaar.workout.entity.Exercise;
import com.fityaar.workout.entity.ExerciseAlias;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Resolves an exercise name from another app ("Bench Press (Barbell)") to a FitYaar exercise
 * ("Barbell Bench Press - Medium Grip"). Built once per import over the catalog + the user's
 * own custom exercises.
 *
 * <p>Order: curated alias → exact normalized name → equipment-reordered name
 * ("Bench Press (Dumbbell)" → "dumbbell bench press") → conservative token-overlap fuzzy match.
 * Returns empty when nothing is confident enough — a wrong match corrupts PRs, so the caller
 * creates a custom exercise instead.
 */
public final class ExerciseMatcher {

    public enum Method { ALIAS, EXACT, FUZZY }

    public record Match(Exercise exercise, Method method) {
    }

    static final double FUZZY_THRESHOLD = 0.6;

    private static final Pattern PAREN_SUFFIX = Pattern.compile("^(.*?)\\s*\\(([^)]*)\\)\\s*$");
    private static final Set<String> STOPWORDS = Set.of("the", "a", "an", "with", "on", "of", "to", "and");
    private static final Map<String, Exercise.Equipment> EQUIPMENT_WORDS = Map.ofEntries(
            Map.entry("barbell", Exercise.Equipment.BARBELL),
            Map.entry("ez bar", Exercise.Equipment.BARBELL),
            Map.entry("dumbbell", Exercise.Equipment.DUMBBELL),
            Map.entry("kettlebell", Exercise.Equipment.KETTLEBELL),
            Map.entry("machine", Exercise.Equipment.MACHINE),
            Map.entry("smith machine", Exercise.Equipment.MACHINE),
            Map.entry("cable", Exercise.Equipment.CABLE),
            Map.entry("band", Exercise.Equipment.BAND),
            Map.entry("bodyweight", Exercise.Equipment.NO_EQUIPMENT),
            Map.entry("plate", Exercise.Equipment.PLATE));

    /**
     * Words that turn a lift into a different movement ("Sumo Squat" is not "Squat", "Lying T-Bar
     * Row" is not "T-Bar Row"). A fuzzy match must agree on all of them, or it's rejected.
     */
    private static final Set<String> VARIANT_WORDS = Set.of(
            "sumo", "pause", "paused", "curtsy", "walking", "bulgarian", "split", "goblet", "box",
            "front", "rear", "back", "overhead", "behind", "reverse", "close", "wide", "narrow",
            "incline", "decline", "flat", "seated", "lying", "kneeling", "prone", "supine",
            "one", "weighted", "assisted", "deficit", "romanian", "stiff", "sissy", "hack", "jump",
            "low", "high", "hammer", "preacher", "spider", "zottman", "drag", "cross", "jm",
            "pendlay", "yates", "landmine", "single");

    private final Map<String, Exercise> byAlias = new HashMap<>();
    private final Map<String, Exercise> byName = new HashMap<>();
    private final List<Candidate> candidates = new ArrayList<>();

    private record Candidate(Exercise exercise, Set<String> tokens) {
    }

    public ExerciseMatcher(Collection<Exercise> visibleExercises, Collection<ExerciseAlias> aliases) {
        for (ExerciseAlias a : aliases) {
            byAlias.put(a.getAliasKey(), a.getExercise());
        }
        // Catalog first, then the user's customs, so a custom with the same name wins.
        List<Exercise> ordered = new ArrayList<>(visibleExercises);
        ordered.sort(Comparator.comparing(e -> Boolean.TRUE.equals(e.getIsCustom())));
        for (Exercise e : ordered) {
            String key = normalize(e.getName());
            Exercise prev = byName.get(key);
            if (prev == null || Boolean.TRUE.equals(e.getIsCustom())
                    || e.getName().length() < prev.getName().length()) {
                byName.put(key, e);
            }
            if (!Boolean.TRUE.equals(e.getIsCustom())) {
                candidates.add(new Candidate(e, tokens(e.getName())));
            }
        }
    }

    public Optional<Match> match(String sourceName) {
        String key = normalize(sourceName);
        if (key.isEmpty()) return Optional.empty();

        Exercise e = byAlias.get(key);
        if (e != null) return Optional.of(new Match(e, Method.ALIAS));

        e = byName.get(key);
        if (e != null) return Optional.of(new Match(e, Method.EXACT));

        // "Bench Press (Dumbbell)" → "dumbbell bench press", then "bench press"
        Matcher m = PAREN_SUFFIX.matcher(sourceName.trim());
        Exercise.Equipment equipment = null;
        if (m.matches()) {
            String base = normalize(m.group(1));
            String qualifier = normalize(m.group(2));
            equipment = EQUIPMENT_WORDS.get(qualifier);
            e = byName.get(normalize(qualifier + " " + base));
            if (e == null) e = byName.get(normalize(base + " " + qualifier));
            if (e == null && equipment == null) e = byName.get(base);
            if (e != null) return Optional.of(new Match(e, Method.EXACT));
        }

        return fuzzy(sourceName, equipment).map(x -> new Match(x, Method.FUZZY));
    }

    /** Equipment named in a "(…)" suffix, for typing custom exercises created on import. */
    public static Exercise.Equipment equipmentOf(String sourceName) {
        Matcher m = PAREN_SUFFIX.matcher(sourceName.trim());
        if (!m.matches()) return null;
        String q = normalize(m.group(2));
        Exercise.Equipment eq = EQUIPMENT_WORDS.get(q);
        if (eq != null) return eq;
        for (var entry : EQUIPMENT_WORDS.entrySet()) {
            if (q.contains(entry.getKey())) return entry.getValue();
        }
        return null;
    }

    private Optional<Exercise> fuzzy(String sourceName, Exercise.Equipment equipment) {
        Set<String> src = tokens(sourceName);
        if (src.isEmpty()) return Optional.empty();
        Exercise best = null;
        double bestScore = 0;
        for (Candidate c : candidates) {
            if (equipment != null && c.exercise.getEquipment() != null
                    && c.exercise.getEquipment() != equipment) {
                continue; // never match a dumbbell lift onto a barbell one
            }
            if (!variantsOf(src).equals(variantsOf(c.tokens))) {
                continue; // e.g. "Pause Squat" must not become "Barbell Squat"
            }
            double score = jaccard(src, c.tokens);
            boolean better = score > bestScore
                    || (score == bestScore && best != null
                    && c.exercise.getName().length() < best.getName().length());
            if (better) {
                best = c.exercise;
                bestScore = score;
            }
        }
        return bestScore >= FUZZY_THRESHOLD ? Optional.ofNullable(best) : Optional.empty();
    }

    private static Set<String> variantsOf(Set<String> tokens) {
        Set<String> out = new HashSet<>();
        for (String t : tokens) {
            if (VARIANT_WORDS.contains(t)) out.add(t);
        }
        return out;
    }

    private static double jaccard(Set<String> a, Set<String> b) {
        int inter = 0;
        for (String t : a) {
            if (b.contains(t)) inter++;
        }
        int union = a.size() + b.size() - inter;
        return union == 0 ? 0 : (double) inter / union;
    }

    static Set<String> tokens(String name) {
        Set<String> out = new HashSet<>();
        for (String t : normalize(name).split(" ")) {
            if (t.isEmpty() || STOPWORDS.contains(t)) continue;
            // crude singular: curls→curl, rows→row, pullups→pullup (but keep "press", "abs")
            if (t.length() > 3 && t.endsWith("s") && !t.endsWith("ss")) t = t.substring(0, t.length() - 1);
            if (t.equals("single")) t = "one"; // "Single Arm" == "One-Arm"
            if (t.equals("paused")) t = "pause";
            out.add(t);
        }
        return out;
    }

    /** Lower-case, every non-alphanumeric run → one space, trimmed. Mirrors V22's SQL. */
    public static String normalize(String name) {
        if (name == null) return "";
        return name.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+", " ").trim();
    }
}
