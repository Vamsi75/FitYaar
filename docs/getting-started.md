# Getting Started with FitYaar

This guide provides instructions on how to build and run the FitYaar application.

## Prerequisites

- **Java 21**: The backend is built using Java 21.
- **PostgreSQL**: Required for the database.
- **Flutter SDK**: Required for the mobile application.
- **Node.js & npm**: Required for the web dashboard.
- **Docker**: Optional, but recommended for running PostgreSQL.

---

## 🚀 Backend (Spring Boot)

### 1. Database Setup
Ensure you have a PostgreSQL instance running. You can create a database named `fityaar`.

If you have Docker installed, you can run:
```bash
docker run --name fityaar-db -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=fityaar -p 5432:5432 -d postgres
```

### 2. Configuration
Update `src/main/resources/application-dev.yml` with your database credentials.

### 3. Build and Run
Navigate to the `FitYaar-Backend` directory:
```bash
cd FitYaar-Backend
mvn spring-boot:run
```

The API will be available at `http://localhost:8080`.
Swagger UI (OpenAPI) can be accessed at `http://localhost:8080/swagger-ui.html`.

---

## 📱 Mobile App (Flutter)

### 1. Install Dependencies
Navigate to the `FitYaar-Mobile` directory:
```bash
cd FitYaar-Mobile
flutter pub get
```

### 2. Run the App
Connect a device or start an emulator and run:
```bash
flutter run
```

---

## 💻 Web Dashboard (React)

### 1. Install Dependencies
Navigate to the `FitYaar-Web` directory:
```bash
cd FitYaar-Web
npm install
```

### 2. Run the Web App
```bash
npm start
```
The dashboard will be available at `http://localhost:3000`.

---

## 🛠 Project Structure
- `FitYaar-Backend/`: Spring Boot API.
- `FitYaar-Mobile/`: Flutter application.
- `FitYaar-Web/`: React-based read-only dashboard.
- `docs/`: Documentation and milestones.
- `database/`: Flyway migrations and seed data.
- `storage/`: Local storage for images and exports.
