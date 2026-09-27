package com.fityaar.notification.repository;

import com.fityaar.notification.entity.DeviceToken;
import com.fityaar.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
    Optional<DeviceToken> findByToken(String token);
    List<DeviceToken> findByUser(User user);
    List<DeviceToken> findByUserIn(Collection<User> users);
    void deleteByToken(String token);
}
