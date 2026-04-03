# Matrix: Asynchronous Multi-Agent Autonomous Organization

Matrix is an AI-first, fully autonomous organization inspired by the social structure of *The Matrix*. It enables a decentralized network of specialized AI agents to collaborate on complex tasks, bridging the digital and physical worlds.

## 🚀 Getting Started

### Prerequisites
- **Flutter**: Stable channel (3.22+)
- **Dart**: 3.4+
- **Docker**: For running the local Appwrite instance
- **Rust**: For the Agent Client core logic

---

### Step 1: Launch Backend (Appwrite)
Matrix uses Appwrite as its central nervous system. We provide a script to handle Docker setup, including socket detection for Docker Desktop on Linux.

```bash
./scripts/launch_appwrite.sh
```
*Follow the terminal prompts. If a web installer starts, visit `http://localhost:20080`.*

### Step 2: Provision Database & Collections
Once Appwrite is running and you have access to the console (`http://localhost`):
1.  Create a new project with ID: `matrix_dev`.
2.  Run the automated setup tool to create the database, collections, and attributes:
    ```bash
    cd scripts/setup_appwrite_tool && dart run bin/setup_appwrite_tool.dart
    ```

### Step 3: Configure Environment
Create a `.env` file in the root directory (linked to both `hq` and `agent` projects):
```env
APPWRITE_ENDPOINT=http://localhost/v1
APPWRITE_PROJECT_ID=matrix_dev
APPWRITE_LOCAL_API_KEY=your_key_from_appwrite_console
```

### Step 4: Run the Applications

#### HQ (Command Center)
The HQ app provides the Oracle Feed and Matrix Kanban board.
```bash
cd hq
flutter run -d macos # or web/android/ios
```

#### Agent Client (Operator Interface)
The Agent app manages local orchestration and hardware (Sentinels).
```bash
cd agent
flutter run -d macos # or android/ios
```

---

## 🏗️ Project Structure

-   `./hq`: Flutter application for human supervisors.
-   `./agent`: Flutter + Rust application for AI agents.
-   `./packages/msp`: **Matrix Service Provider** layer. PROVIDER-AGNOSTIC abstraction for Auth, Database, and Storage.
-   `./scripts`: Automation tools for backend provisioning and launch.
-   `./design`: Core design documents, UI mockups, and guidelines.
-   `./third_party`: Reusable submodules (including `vibe-kanban` and `claude-code`).

---

## 🧪 Verification & Testing

### Integration Tests
Run end-to-end authentication and dashboard flows:
```bash
cd hq && flutter test integration_test/app_test.dart
```

### Static Analysis
```bash
cd hq && flutter analyze
cd agent && flutter analyze
cd packages/msp && dart analyze
```

---

## 📘 Documentation
Detailed architectural insights, entity schemas, and implemention roadmaps can be found in:
👉 [**Matrix Core Design**](./design/matrix-core-design.md)
