package com.fityaar.gym.event;

import com.fityaar.gym.service.GymService;
import com.fityaar.workout.event.WorkoutFinishedEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

/** When a workout is finished, auto check-out the user from any gym so the live count updates. */
@Component
@RequiredArgsConstructor
public class GymCheckoutListener {

    private final GymService gymService;

    @EventListener
    public void onWorkoutFinished(WorkoutFinishedEvent event) {
        gymService.checkoutUserEverywhere(event.user());
    }
}
