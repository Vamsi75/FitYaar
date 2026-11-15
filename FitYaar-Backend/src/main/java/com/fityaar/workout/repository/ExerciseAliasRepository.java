package com.fityaar.workout.repository;

import com.fityaar.workout.entity.ExerciseAlias;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface ExerciseAliasRepository extends JpaRepository<ExerciseAlias, Long> {

    /** All aliases with their target exercise loaded (small table; cached per import). */
    @Query("SELECT a FROM ExerciseAlias a JOIN FETCH a.exercise")
    List<ExerciseAlias> findAllWithExercise();
}
