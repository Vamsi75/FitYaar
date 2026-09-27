# FitYaar Project: Complete Execution & IDE Configuration Guide

This guide provides instructions to run all components of the FitYaar ecosystem: **Backend (Spring Boot)**, **Mobile (Flutter)**, and **Web (Next.js)**.

---

## 1. Prerequisites
Ensure the following are installed and configured on your Mac:
- **Flutter SDK**: `~/development/flutter` (Version 3.10+ / Dart 3.10+)
- **Java JDK**: Microsoft OpenJDK 21 (Path: `/Users/vamsih/Library/Java/JavaVirtualMachines/ms-21.0.12.1/Contents/Home`)
- **Node.js**: For the Web project (`npm` installed).
- **PostgreSQL**: With `pgAdmin 4` or `psql` command line.
- **Android Studio**: For Emulator and SDK tools.

---

## 2. Database Setup (Postgres)
1. **Create Database**: Create a database named `fityaar` in pgAdmin.
2. **Run Migrations**: 
   - Execute `/Users/vamsih/FitYaar/migration/creation.sql` first.
   - Execute `/Users/vamsih/FitYaar/migration/data.sql` second.
   *Note: If using pgAdmin Query Tool, delete the lines starting with `\` at the top of the files.*

---

## 3. FitYaar Backend (Spring Boot)
- **Port**: 2098
- **Database Config**: Check `FitYaar-Backend/src/main/resources/application.yml`.

### IntelliJ IDEA Configuration
1. Open the `FitYaar-Backend` folder.
2. Go to **File > Project Structure > Project**.
3. Set **SDK** to `ms-21` (OpenJDK 21).
4. Right-click `FitYaarApplication.java` -> **Run**.

### VS Code Configuration
1. Install **Extension Pack for Java** and **Spring Boot Extension Pack**.
2. Open the `FitYaar-Backend` folder.
3. Click the **Run** button above the `main` method in `FitYaarApplication.java`.

---

## 4. FitYaar Mobile (Flutter)
- **Port**: Communicates with Backend on 2098.

### IntelliJ IDEA Configuration
1. **Plugins**: Install "Flutter" and "Dart" plugins.
2. **SDK**: **Settings > Languages & Frameworks > Flutter**. Set path to `~/development/flutter`.
3. **Run**: Select your emulator/device in the toolbar and press the green **Play** button.

### VS Code Configuration
1. **Extension**: Install the **Flutter** extension.
2. **SDK**: If prompted, point to `~/development/flutter`.
3. **Run**: Open `lib/main.dart`, press `F5` or go to the "Run and Debug" tab.
4. **Environment Variables**: To run on a physical device, use the Debug Console or terminal:
   `flutter run --dart-define=API_BASE_URL=http://<YOUR_MAC_IP>:2098`

---

## 5. FitYaar Web (Next.js & HTML)

### SuperAdmin HTML
- Simply open `FitYaar-Web/superadmin.html` in a browser.
- Ensure "API base URL" is `http://localhost:2098`.

### Next.js Web App
1. **Terminal**: `cd FitYaar-Web`
2. **Install**: `npm install`
3. **Run**: `npm run dev`
4. **Access**: `http://localhost:3000`

---

## 6. Quick Start Commands (Terminal)
| Component | Command |
| :--- | :--- |
| **Backend** | `./mvnw spring-boot:run` (Inside FitYaar-Backend) |
| **Mobile** | `flutter run` (Inside FitYaar-Mobile) |
| **Web** | `npm run dev` (Inside FitYaar-Web) |

---

## 7. Troubleshooting
- **Android Build Failure**: Ensure Flutter is using the correct JDK:
  `flutter config --jdk-dir="/Users/vamsih/Library/Java/JavaVirtualMachines/ms-21.0.12.1/Contents/Home"`
- **Connection Issues**: Emulator uses `10.0.2.2:2098` to see the Mac. Physical devices need the Mac's LAN IP.
