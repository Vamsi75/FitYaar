package com.fityaar.notification.entity;

import com.fityaar.common.BaseAuditEntity;
import com.fityaar.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

/** An FCM registration token for one device, owned by the user who last registered it. */
@Entity
@Table(name = "device_tokens")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeviceToken extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, unique = true)
    private String token;

    private String platform; // android / ios / web
}
