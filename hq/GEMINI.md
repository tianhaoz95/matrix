# Matrix Project: hq & program

## Overview
The `matrix` project is a monorepo containing two main Flutter applications: `hq` (Headquarters) and `program`. Both applications leverage high-performance Rust logic via `flutter_rust_bridge` (v2) and integrate with Firebase for backend services.

- **Architecture**: A multi-application workspace where `hq` and `program` reside in parallel directories.
- **Core Technologies**: Flutter (Dart), Rust, `flutter_rust_bridge`, and Firebase.
- **Inter-op**: The `rust_builder` directory acts as a glue layer to build and link Rust code as a plugin across all supported platforms (Android, iOS, macOS, Windows, Linux, and Web).

## Project Structure
- `hq/`: The primary Flutter application directory.
- `program/`: A sibling Flutter application directory.
- `hq/rust/`: Contains the Rust source code and logic.
- `hq/rust_builder/`: FFI-based bridge logic for building the Rust library into the Flutter app.
- `hq/lib/src/rust/`: Generated Dart bindings for the Rust API.

## Building and Running

### Prerequisites
- Flutter SDK
- Rust (Cargo)
- `flutter_rust_bridge_codegen` (for code generation)
- Firebase CLI (for Firebase features)

### Key Commands

#### Flutter Development
- **Get Dependencies**: `flutter pub get`
- **Run App**: `flutter run`
- **Analyze Code**: `flutter analyze`
- **Run Tests**: `flutter test`

#### Rust Integration
- **Generate Bridge Code**: 
  ```bash
  flutter_rust_bridge_codegen generate
  ```
- **Build Rust Library**: Handled automatically by Flutter's build process via the `rust_builder` plugin.

#### Firebase
- **Configure Firebase**: `flutterfire configure`
- **Firebase Login**: `firebase login`

## Development Conventions

### Rust & Dart Interop
- Rust logic resides in `hq/rust/src/api/`.
- Use `#[flutter_rust_bridge::frb(sync)]` for synchronous calls when performance/simplicity allows.
- Always initialize the Rust library in `main.dart` using `await RustLib.init()`.

### Firebase Integration
- Initialize Firebase in the `main()` function before `runApp()`:
  ```dart
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ```
- Firebase configuration is managed via `firebase_options.dart`.

### Coding Style
- Follow standard Flutter/Dart lint rules (defined in `analysis_options.yaml`).
- Clean up boilerplate comments in configuration files (`pubspec.yaml`, `build.gradle.kts`, etc.) to keep the codebase focused.
- Ensure cross-platform compatibility by verifying changes in the `rust_builder` for all target OSs.
