# Configuration Guide

FitYaar uses various configuration files and environment variables to manage different environments.

## 🛠 Backend Configuration (Spring Boot)

The backend uses Spring Boot's multi-profile configuration system.

### Configuration Files
- `src/main/resources/application.yml`: Base configuration (common to all profiles).
- `src/main/resources/application-dev.yml`: Development settings (H2 or local Postgres).
- `src/main/resources/application-prod.yml`: Production settings.

### Key Environment Variables
If you prefer not to hardcode values in `.yml` files, you can use environment variables:

| Variable | Description | Default Value                              |
| --- | --- |--------------------------------------------|
| `DB_URL` | PostgreSQL JDBC URL | `jdbc:postgresql://localhost:5432/fityaar` |
| `DB_USERNAME` | Database username | `postgres`                                 |
| `DB_PASSWORD` | Database password | `root`                                     |
| `JWT_SECRET` | Secret key for signing JWTs | `a-very-secure-secret-key-change-it`       |
| `GOOGLE_CLIENT_ID` | For Google Sign-In | `your-google-client-id`                    |

### Security Note
**Never** commit your production secrets to version control. Use environment variables or a secret management service (like Vault or AWS Secrets Manager) in production.

---

## 📱 Mobile Configuration (Flutter)

Mobile configuration is handled through `.env` files or native config files.

- `lib/core/constants/api_constants.dart`: Contains the base URL for the API.
- `android/app/build.gradle`: Android-specific configuration (package name, version).
- `ios/Runner/Info.plist`: iOS-specific configuration (permissions).

---

## 💻 Web Configuration (React)

- `.env`: Create this file in the `FitYaar-Web` root for environment variables.
- `REACT_APP_API_URL`: The URL of the backend API (e.g., `http://localhost:8080/api`).
