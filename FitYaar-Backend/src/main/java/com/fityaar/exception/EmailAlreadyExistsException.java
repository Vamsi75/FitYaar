package com.fityaar.exception;

/** Thrown when registering an email that already exists. Mapped to HTTP 409 by {@link GlobalExceptionHandler}. */
public class EmailAlreadyExistsException extends RuntimeException {
    public EmailAlreadyExistsException(String email) {
        super("Email already registered: " + email);
    }
}
