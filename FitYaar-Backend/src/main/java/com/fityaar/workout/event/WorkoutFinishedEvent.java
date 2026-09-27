package com.fityaar.workout.event;

import com.fityaar.user.entity.User;

/** Published when a user finishes a workout session. */
public record WorkoutFinishedEvent(User user) {
}
