# RootAppNews - Flutter Clean Architecture

A highly scalable Flutter News Application demonstrating Enterprise-grade Clean Architecture paradigms, extensive widget encapsulation, and sophisticated Global Error Handling mechanisms.

## Project Context
This application is powered by `fvm` (Flutter Version Management). Always ensure `fvm flutter` is used in place of the raw `flutter` command to avoid mismatch constraints and dependency hell.

---

## 🚀 Getting Started

### 1. Requirements
Ensure you are using `fvm`. If not installed:
```bash
dart pub global activate fvm
```

Install the specific Flutter SDK version defined in the `.fvmrc`:
```bash
fvm install
fvm use
```

### 2. Install Dependencies
```bash
fvm flutter pub get
```

### 3. Running the App
```bash
fvm flutter run
```

---

## 🧪 Testing Guidelines & CLI Commands

This repository enforces a strong testing culture. Below are the bash scripts and commands required to validate the codebase.

### Running All Unit & Widget Tests
To run all test suites across the entire application (Core Network, Interceptors, UseCases, Mappers, etc.):
```bash
fvm flutter test
```

### Running Tests for a Specific File
If you are iterating on a single file and want rapid feedback:
```bash
fvm flutter test test/core/network/api_client_test.dart
```

### Generating Test Coverage Report
To view how much percentage of the codebase is covered by unit tests, generate an LCOV report:
```bash
fvm flutter test --coverage
```

Once the `coverage/lcov.info` file is generated, you can convert it to HTML (requires `lcov` to be installed on your Mac, e.g., `brew install lcov`):
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 🏗️ Architecture Philosophy

*   **GlobalAlertBloc**: A centralized interception engine tied deeply to `ApiClient` (Dio). Capable of invoking robust BottomSheets context-free whenever a `DioExceptionType.connectionError` or `timeout` strikes.
*   **Lifting State Down**: Visual component specific states (like `obscureText` in a Password field) are thoroughly encapsulated inside specific isolated UI elements like `AuthPasswordTextField` rather than polluting full-page renders.
*   **Decoupled Navigation**: Controlled routing via `GoRouter` using `GlobalKey<NavigatorState>` injected at a root application level.
