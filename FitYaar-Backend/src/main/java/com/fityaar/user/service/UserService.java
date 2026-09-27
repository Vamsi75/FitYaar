package com.fityaar.user.service;

import com.fityaar.exception.EmailAlreadyExistsException;
import com.fityaar.exception.ResourceNotFoundException;
import com.fityaar.user.dto.ProfileRequest;
import com.fityaar.user.dto.ProfileResponse;
import com.fityaar.user.dto.UserRequest;
import com.fityaar.user.dto.UserResponse;
import com.fityaar.user.entity.Profile;
import com.fityaar.user.entity.User;
import com.fityaar.user.repository.UserRepository;
import com.fityaar.subscription.dto.EntitlementView;
import com.fityaar.subscription.service.EntitlementService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final EntitlementService entitlementService;

    @Transactional
    public User register(UserRequest request) {
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new EmailAlreadyExistsException(request.getEmail());
        }

        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(User.Role.USER)
                .build();

        Profile profile = Profile.builder()
                .user(user)
                .displayName(request.getDisplayName())
                .isPublic(true)
                .gymVisible(true)
                .build();

        user.setProfile(profile);
        return userRepository.save(user);
    }

    @Transactional
    public ProfileResponse updateProfile(User user, ProfileRequest request) {
        Profile profile = user.getProfile();

        if (request.getDisplayName() != null) profile.setDisplayName(request.getDisplayName());
        if (request.getProfilePictureUrl() != null) profile.setProfilePictureUrl(request.getProfilePictureUrl());
        if (request.getBio() != null) profile.setBio(request.getBio());
        if (request.getFitnessGoal() != null) profile.setFitnessGoal(request.getFitnessGoal());
        if (request.getGender() != null) profile.setGender(request.getGender());
        if (request.getBirthday() != null) profile.setBirthday(request.getBirthday());
        if (request.getInstagram() != null) profile.setInstagram(request.getInstagram());
        if (request.getWebsite() != null) profile.setWebsite(request.getWebsite());
        if (request.getCurrentWeight() != null) profile.setCurrentWeight(request.getCurrentWeight());
        if (request.getTargetWeight() != null) profile.setTargetWeight(request.getTargetWeight());
        if (request.getHeight() != null) profile.setHeight(request.getHeight());
        if (request.getWaist() != null) profile.setWaist(request.getWaist());
        if (request.getBodyFatPercentage() != null) profile.setBodyFatPercentage(request.getBodyFatPercentage());
        if (request.getDailyCalorieGoal() != null) profile.setDailyCalorieGoal(request.getDailyCalorieGoal());
        if (request.getDailyWaterGoal() != null) profile.setDailyWaterGoal(request.getDailyWaterGoal());
        if (request.getIsPublic() != null) profile.setIsPublic(request.getIsPublic());
        if (request.getGymVisible() != null) profile.setGymVisible(request.getGymVisible());
        if (request.getPhone() != null) profile.setPhone(request.getPhone());

        if (request.getTheme() != null) user.setTheme(request.getTheme());
        if (request.getLanguage() != null) user.setLanguage(request.getLanguage());
        if (request.getWeightUnit() != null) user.setWeightUnit(request.getWeightUnit());
        if (request.getDistanceUnit() != null) user.setDistanceUnit(request.getDistanceUnit());
        if (request.getMeasurementUnit() != null) user.setMeasurementUnit(request.getMeasurementUnit());

        userRepository.save(user);
        return mapToProfileResponse(profile);
    }

    public ProfileResponse getProfile(User user) {
        return mapToProfileResponse(user.getProfile());
    }

    public User findById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + id));
    }

    @Transactional
    public void changePassword(User user, String currentPassword, String newPassword) {
        if (!passwordEncoder.matches(currentPassword, user.getPassword())) {
            throw new IllegalArgumentException("Incorrect current password");
        }
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    @Transactional
    public void updateEmail(User user, String newEmail, String password) {
        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new IllegalArgumentException("Incorrect password");
        }
        if (userRepository.findByEmail(newEmail).isPresent()) {
            throw new EmailAlreadyExistsException(newEmail);
        }
        user.setEmail(newEmail);
        userRepository.save(user);
    }

    @Transactional
    public void deleteAccount(User user) {
        user.setStatus(User.Status.DEACTIVATED);
        userRepository.save(user);
    }

    public UserResponse toUserResponse(User user) {
        EntitlementView ent = entitlementService.view(user);
        return UserResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .displayName(user.getProfile() != null ? user.getProfile().getDisplayName() : null)
                .role(user.getRole())
                .pro(ent.isPro())
                .plan(ent.getPlan())
                .until(ent.getUntil())
                .build();
    }

    private ProfileResponse mapToProfileResponse(Profile profile) {
        return ProfileResponse.builder()
                .id(profile.getId())
                .email(profile.getUser().getEmail())
                .displayName(profile.getDisplayName())
                .profilePictureUrl(profile.getProfilePictureUrl())
                .bio(profile.getBio())
                .fitnessGoal(profile.getFitnessGoal())
                .currentWeight(profile.getCurrentWeight())
                .targetWeight(profile.getTargetWeight())
                .height(profile.getHeight())
                .waist(profile.getWaist())
                .bodyFatPercentage(profile.getBodyFatPercentage())
                .dailyCalorieGoal(profile.getDailyCalorieGoal())
                .dailyWaterGoal(profile.getDailyWaterGoal())
                .isPublic(profile.getIsPublic())
                .gymVisible(profile.getGymVisible())
                .gender(profile.getGender())
                .birthday(profile.getBirthday())
                .instagram(profile.getInstagram())
                .website(profile.getWebsite())
                .phone(profile.getPhone())
                .theme(profile.getUser().getTheme())
                .language(profile.getUser().getLanguage())
                .weightUnit(profile.getUser().getWeightUnit())
                .distanceUnit(profile.getUser().getDistanceUnit())
                .measurementUnit(profile.getUser().getMeasurementUnit())
                .build();
    }
}
