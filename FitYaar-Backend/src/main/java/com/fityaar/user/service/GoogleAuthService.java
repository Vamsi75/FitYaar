package com.fityaar.user.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fityaar.user.entity.Profile;
import com.fityaar.user.entity.User;
import com.fityaar.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

/**
 * Verifies a Google ID token via Google's tokeninfo endpoint and returns (creating if needed)
 * the matching user. Set app.google.client-id (GOOGLE_CLIENT_ID) to enforce the audience.
 */
@Service
@RequiredArgsConstructor
public class GoogleAuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.google.client-id:}")
    private String googleClientId;

    private final ObjectMapper mapper = new ObjectMapper();
    private final HttpClient http = HttpClient.newHttpClient();

    @Transactional
    public User verifyAndGetUser(String idToken) {
        JsonNode claims = fetchClaims(idToken);

        if (googleClientId != null && !googleClientId.isBlank()
                && !googleClientId.equals(claims.path("aud").asText())) {
            throw new BadCredentialsException("Google token audience mismatch");
        }
        String email = claims.path("email").asText(null);
        if (email == null || email.isBlank()) {
            throw new BadCredentialsException("Google token has no email");
        }
        String googleId = claims.path("sub").asText(null);
        String name = claims.path("name").asText(email);

        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) {
            user = User.builder()
                    .email(email)
                    .password(passwordEncoder.encode(UUID.randomUUID().toString()))
                    .role(User.Role.USER)
                    .googleId(googleId)
                    .build();
            user.setProfile(Profile.builder().user(user).displayName(name).isPublic(true).gymVisible(true).build());
            return userRepository.save(user);
        }
        if (user.getGoogleId() == null) {
            user.setGoogleId(googleId);
            userRepository.save(user);
        }
        return user;
    }

    private JsonNode fetchClaims(String idToken) {
        try {
            HttpRequest req = HttpRequest.newBuilder(URI.create(
                    "https://oauth2.googleapis.com/tokeninfo?id_token="
                            + URLEncoder.encode(idToken, StandardCharsets.UTF_8))).GET().build();
            HttpResponse<String> resp = http.send(req, HttpResponse.BodyHandlers.ofString());
            if (resp.statusCode() != 200) {
                throw new BadCredentialsException("Invalid Google token");
            }
            return mapper.readTree(resp.body());
        } catch (BadCredentialsException e) {
            throw e;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new BadCredentialsException("Could not verify Google token");
        } catch (Exception e) {
            throw new BadCredentialsException("Could not verify Google token");
        }
    }
}
