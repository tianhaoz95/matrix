# Matrix Project

A monorepo containing two Flutter applications with Rust integrations via `flutter_rust_bridge` and Firebase connectivity.

## Project Structure

- `hq/`: The "Matrix HQ" Flutter application.
  - `lib/`: Flutter source code.
  - `rust/`: Rust library backend for HQ.
  - `rust_builder/`: Dart package to build the Rust library.
- `program/`: The "Matrix Program" Flutter application.
  - `lib/`: Flutter source code.
  - `rust/`: Rust library backend for Program.
  - `rust_builder/`: Dart package to build the Rust library.

## Main Technologies

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Native Logic:** [Rust](https://www.rust-lang.org/)
- **Bridge:** [flutter_rust_bridge v2](https://cjycode.com/flutter_rust_bridge/)
- **Backend Services:** [Firebase](https://firebase.google.com/)

## Getting Started

### Prerequisites

- Flutter SDK
- Rust toolchain (`rustup`)
- `flutter_rust_bridge_codegen` (v2.11.1)
- Firebase CLI (for configuration)

### Building and Running

Each application (`hq` and `program`) is a standalone Flutter project. To run either:

1.  Navigate to the app directory (e.g., `cd hq`).
2.  (Optional) Generate/regenerate Rust bridge code:
    ```bash
    flutter_rust_bridge_codegen generate
    ```
3.  Run the Flutter app:
    ```bash
    flutter run
    ```

### Testing

Run standard Flutter tests from within the `hq/` or `program/` directories:

```bash
flutter test
flutter test integration_test/simple_test.dart
```

## Development Conventions

- **Rust Logic:** Core logic should be placed in `rust/src/api/`. Use `#[flutter_rust_bridge::frb(sync)]` for synchronous functions if appropriate.
- **Firebase:** Both applications are configured to use the `matrix-platform` Firebase project. Configuration is managed via `firebase.json` and `lib/firebase_options.dart`.
- **Formatting:** Adhere to standard Flutter/Dart linting (`analysis_options.yaml`) and Rust formatting (`cargo fmt`).

## Firebase Integration

Both apps are connected to the `matrix-platform` project:
- **Project ID:** `matrix-platform`
- **Supported Platforms:** Android, iOS, macOS, Web, Windows.
