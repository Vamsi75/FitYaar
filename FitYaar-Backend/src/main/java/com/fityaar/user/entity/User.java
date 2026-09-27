package com.fityaar.user.entity;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import com.fityaar.common.BaseAuditEntity;
import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.util.Set;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User extends BaseAuditEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Email
    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false)
    private String password;

    private String googleId;

    @Enumerated(EnumType.STRING)
    private Role role;

    /** Account lifecycle. Only ACTIVE users can authenticate (see UserPrincipal.isEnabled). */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private Status status = Status.ACTIVE;

    @Column
    private String theme; // light, dark, system

    @Column
    private String language; // en, hi, etc.

    @Column
    private String weightUnit; // kg, lb

    @Column
    private String distanceUnit; // km, mi

    @Column
    private String measurementUnit; // cm, in

    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL)
    @JsonManagedReference
    private Profile profile;

    public enum Role {
        USER, PREMIUM, ADMIN
    }

    public enum Status {
        INVITED, ACTIVE, SUSPENDED, DEACTIVATED
    }
}

