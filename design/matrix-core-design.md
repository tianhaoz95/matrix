# Matrix: Asynchronous Multi-Agent Autonomous Organization

## 1. Project Vision
Matrix is an AI-first, fully autonomous organization inspired by the social structure of *The Matrix*. It enables a decentralized network of specialized AI agents to collaborate on complex tasks, bridging the digital and physical worlds.

The system is designed for **asynchronous autonomy**: humans provide high-level intent, and the organization (HQ + Agents) decomposes, executes, and validates the work without constant human oversight.

---

## 2. System Architecture

### 2.1 Component Overview
*   **The HQ (Headquarters):** The central nervous system. A persistent backend and management dashboard.
*   **The Agent Clients:** Distributed compute nodes running specialized AI personas. Each client is a self-contained unit capable of local orchestration.
*   **The Matrix Service Provider (MSP) Layer:** A provider-agnostic abstraction layer that sits between the application logic and the backend infrastructure. This allows the system to switch between vendors (Appwrite, Firebase, Supabase) or internal enterprise stacks with minimal code changes.

### 2.2 Roles & Personas
| Role | Count | Responsibility |
| :--- | :--- | :--- |
| **The Architect** | 1 | Strategic lead. Task decomposition, resource allocation, and final quality assurance. |
| **The Oracle** | 1 | Human-AI bridge. Translates human "prophecies" (intents) into technical requirements and summarizes organizational progress for humans. |
| **Agent** | N | Digital specialist. Handles code development, security auditing, documentation, and CI/CD. |
| **Sentinel** | N | Physical interface. Manages hardware, IoT devices, robot arms, or mobile device testing. |

---

## 3. Infrastructure & Tech Stack

### 3.1 The MSP Abstraction Layer
The Matrix utilizes a dependency injection pattern to interact with backend services. Core interfaces (Providers) are defined in both Flutter (Dart) and Rust:
*   **`IAuthProvider`**: Handles signup, login, session persistence, and workspace (team) management.
*   **`IDataProvider`**: Handles CRUD operations and Realtime event subscriptions for all collections (Tasks, Agents, Logs).
*   **`IStorageProvider`**: Handles file uploads (artifacts, logs) and retrieval.

### 3.2 Primary Implementation: Appwrite
The reference implementation uses **Appwrite** as the service provider.
*   **Frontend:** **Flutter (Web/Desktop/Mobile)**.
*   **Backend-as-a-Service:**
    *   **Auth:** Implements `IAuthProvider` using Appwrite Auth and Teams.
    *   **Database:** Implements `IDataProvider` using Appwrite Databases.
    *   **Realtime:** Uses Appwrite Realtime for WebSocket synchronization.
    *   **Storage:** Implements `IStorageProvider` using Appwrite Buckets.

### 3.3 The Agent Client
*   **Frontend/Controller:** **Flutter (Desktop/Android/iOS)**.
*   **Authentication & Connection:**
    *   **User Sign-In:** The agent client uses the `IAuthProvider` to sign in.
    *   **Workspace Selection:** Upon sign-in, the user selects the workspace the agent should join via the MSP.
    *   **Secure Session:** The MSP manages the secure, persistent session.
*   **Core Logic (Rust):** Integrated via `flutter_rust_bridge`, utilizing optimized libraries from `vibe-kanban`:
    *   **Agentic Coding Framework:** Utilizes `vibe-kanban/services/container.rs` and `StandardCodingAgentExecutor` to manage complex coding turns, including planning and self-correction.
    *   **Model Context Protocol (MCP):** Implements an MCP Task Server to provide LLMs (like Gemini) with standardized tools for repository access, workspace management, and task attempts.
    *   **Codebase Intelligence:** Leverages `vibe-kanban/file_ranker` for RAG-based file discovery and `DiffStream` for real-time code change visualization.
    *   **Git Worktree Management:** Powered by `vibe-kanban/worktree-manager`, enabling isolated feature development.
    *   **Task Execution:** Powered by `vibe-kanban/executors`, providing a unified interface for shell and tool calls.
    *   **Local Orchestration:** Planning sub-tasks, managing local state, and executing tool calls.
    *   **LLM Interface:** Integration with remote APIs (OpenAI, Anthropic, Gemini) or **optional** local LLM orchestration (via `llama-cpp` or `candle`).
    *   **System Exploration:** Autonomous discovery of local tools (git, compilers, ADB), hardware (USB devices, GPUs), and system resources.
    *   **Hardware Interfacing:** For Sentinels (USB/Serial/Bluetooth/ADB).

---

## 4. UI/UX Design & Brand Guidelines

### 4.1 Visual Identity
*   **Design Guideline:** All interfaces must strictly adhere to the principles defined in `design/ui/v1/guideline/DESIGN.md`.
*   **Iconography & Logo:** The primary visual identity is defined by `design/ui/v1/logo/screen.png`. This asset should be used for app icons, splash screens, and branding within the HQ and Agent Client.

### 4.2 HQ: The Command Center
*   **Aesthetic:** *Brutalist-Refined*. A dark, high-contrast theme (Matrix Green/Deep Gray) with clean typography (JetBrains Mono/Inter).
*   **UI Mockups:** Refer to the detailed mockups in `design/ui/v1/app/hq/` for:
    *   **Onboarding:** `sign_in/`, `sign_up/`, `forgot_password/`
    *   **Operation:** `dashboard/`, `new_task/`, `task_detail/`, `profile/`
*   **Responsive Layout:** 
    *   **Desktop/Web:** Multi-pane dashboard with persistent sidebars for navigation and agent status.
    *   **Mobile:** Tab-based interface focusing on the Oracle's Feed and active task tracking.

### 4.3 Client: The Operator Interface
*   **Aesthetic:** Minimalist and high-performance, focused on throughput and local environment health.
*   **UI Mockups:** Refer to the detailed mockups in `design/ui/v1/app/agent/` for:
    *   **Onboarding:** `sign_in/`
    *   **Configuration:** `settings/`
*   **Capability Explorer:** A dedicated screen to initiate "System Scans" and approve Markdown-based capability reports.
*   **The Log Stream:** Realtime terminal-like output showing the agent's internal thought process (Chain-of-Thought).
*   **Physical Feedback (Sentinel Only):** Visual indicators of connected hardware status.

---

## 5. Agentic Loop & Autonomous Workflows

### 5.1 The "Prophecy" Loop (File-Centric Workflow)
All communication and task management in the Matrix are driven by **Markdown Documents with YAML Front Matter**, utilizing an optimized agentic loop inspired by high-performance autonomous systems.

1.  **Intent Reception (The Prophecy):** A human creates a "Request" document in HQ (`status: draft`).
2.  **Oracle Interpretation & Pre-fetching:** 
    *   The Oracle translates the intent and initiates **Background Capability Pre-fetching**. 
    *   It scans for relevant Agent/Sentinel `capability.md` files while the Architect is being alerted.
    *   `status: interpreted`, `responsible_party: the_architect`.
3.  **Architect Decomposition:** The Architect analyzes the Request and pre-fetched data to generate granular "Task" documents.
    *   `status: pending`, `dependencies: [task_id_n]`.
4.  **Dependency & Token Budgeting:** 
    *   The Architect monitors task dependencies. A task is only marked `ready_for_execution` when all blockers are `completed`.
    *   **Token/Resource Guard:** The Architect tracks cumulative resource usage and may "nudge" or pause Agents if they exceed a workspace budget.
5.  **Autonomous Execution & Local Orchestration:**
    *   Agents/Sentinels scan for tasks where `status: ready_for_execution`.
    *   **Local Resume Logic:** If a task was previously interrupted, the Agent uses the most recent `Progress Logs` to resume mid-thought.
    *   **Reporting:** The Agent updates the HQ Task document with progress logs in the Markdown body and status updates in the YAML.
6.  **Validation & Quality Assurance:** 
    *   **Automated Stop Hooks:** Before human review, the Architect executes automated validation hooks (e.g., `npm test`, hardware checks).
    *   **Approval:** Marks task `completed`, unblocking dependent tasks.
    *   **Nudge-based Rejection:** If output is insufficient, Architect updates status to `revision_needed` and provides a **Refinement Nudge**.
    *   **Refinement**: The Architect updates the original **Task Description** to include missing requirements, ensuring persistent knowledge for future attempts.
    *   **Re-assignment:** If the Agent is unable to fulfill the task, the Architect resets it to `pending` with updated requirements.
7.  **Final Synthesis:** Once all tasks are `completed`, the Oracle synthesizes a final "Human Report."

### 5.2 Entity Schema Example (Task Markdown - Revision Needed)
```markdown
---
id: task_082
parent_id: request_441
title: "Implement Rust-based ADB Discovery"
status: revision_needed
responsible_party: sentinel
dependencies: [task_081]
priority: high
capability_requirements: [adb_access, rust_toolchain]
created_at: 2026-04-02T10:00:00Z
---

# Task Description (Updated by Architect)
Implement the discovery logic in the Rust core to list all connected Android devices via ADB. **Must support both USB and network-connected (Wi-Fi) devices.**

## Progress Logs
- [2026-04-02 10:15] Agent_Sentinel_01: Starting scan...
- [2026-04-02 10:45] Agent_Sentinel_01: Finished. Submitted for review.

# Review Feedback (The Architect)
The implementation only discovers devices connected via USB. It must also support network-connected devices (ADB over Wi-Fi). I have updated the Task Description to reflect this requirement.
```

### 5.3 Capability Discovery Workflow
1.  **Authorization:** The user grants the Agent Client permission to scan the host system.
2.  **Autonomous Scan:** The Rust core logic runs diagnostic tools (e.g., `which git`, `lscpu`, `adb devices`).
3.  **Synthesis:** The Agent Client compiles raw diagnostic data into a human-readable and Architect-legible Markdown statement.
4.  **User Review:** The user can edit the synthesized statement in the Client UI.
5.  **Synchronization:** Upon approval, the statement is pushed to HQ via the MSP Layer.

### 5.4 AI Coding Agent Workflow
When the Architect delegates a code-related task to an Agent, the client initiates the following specialized loop:
1.  **Environment Setup:** Using `ContainerService`, the agent creates a dedicated git worktree and initializes an `ExecutionProcess`.
2.  **Context Retrieval:** The `FileRanker` identifies relevant files to populate the LLM's context window.
3.  **The Coding Turn:** The Agent executes a series of "turns" using the `StandardCodingAgentExecutor`, streaming real-time diffs back to HQ via `DiffStream`.
4.  **Verification:** The Agent runs automated tests within its container to verify the fix.
5.  **Submission:** Upon successful verification, the Agent updates the Task Markdown with its changes and marks it for Architect review.

---

## 6. Data Model (Appwrite Collections)

All collections are scoped by **Permissions** (User/Team-level access) and contain a `workspace_id` to ensure isolation.

*   **`workspaces` (Appwrite Teams)**: Built-in Appwrite Teams are used to manage membership.
*   **`agents`**: `id`, `workspace_id`, `name`, `role`, `status`, `capability_statement`.
*   **`tasks`**: `id`, `workspace_id`, `title`, `description`, `assigned_to`, `status`, `priority`, `parent_task_id`, `artifacts` (array of links).
*   **`messages`**: `id`, `workspace_id`, `sender_id`, `content`, `timestamp`, `thread_id`.
*   **`logs`**: `id`, `workspace_id`, `agent_id`, `content`, `timestamp`.

## 8. Implementation Roadmap & Testing Plan

### Phase 1: Foundation & MSP Layer
*   [ ] **MSP Core Interfaces:** Define `IAuthProvider`, `IDataProvider`, and `IStorageProvider` in both Dart and Rust.
    *   **Test:** Unit tests for interface definitions and mock implementations ensuring type safety across the FFI boundary.
*   [ ] **Appwrite Reference Implementation:**
    *   [ ] Setup Appwrite Project and Collections (Agents, Tasks, Messages, Logs).
        *   **Test:** Schema validation tests using Appwrite SDK to ensure collections match the Data Model.
    *   [ ] Implement `AppwriteAuthProvider` with Team-based workspaces.
        *   **Test:** Integration tests for signup, login, and workspace creation/switching.
    *   [ ] Implement `AppwriteDataProvider` with Realtime subscription support.
        *   **Test:** End-to-end Realtime tests: push a task update to Appwrite and verify the subscriber receives the event within <200ms.

### Phase 2: HQ Development (The Command Center)
*   [ ] **HQ Frontend Scaffolding:** Initialize Flutter project for Web/Desktop/Mobile.
    *   **Test:** Build smoke tests for all target platforms (Web, iOS, Android, macOS, Windows).
*   [ ] **Authentication Flows:** Implement "The Construct" (Login/Signup) and Workspace Selector using `design/ui/v1/app/hq/sign_in/`.
    *   **Test:** Widget/Golden tests for UI components; integration tests for the full auth-to-dashboard flow.
*   [ ] **The Matrix (Kanban):** Build the task board with multi-lane support and vertical list-view for mobile.
    *   **Test:** Drag-and-drop widget tests; responsive layout tests ensuring no overflow on small screens.
*   [ ] **The Oracle's Feed:** Implement the real-time activity summary component.
    *   **Test:** Stream-based unit tests; verify feed updates automatically on database events.
*   [ ] **Agent Registry:** Build the sidebar to display connected agents and their capability statements.
    *   **Test:** Verify agent online/offline status toggles correctly in the UI.

### Phase 3: Agent Client Core (The Sentinel/Agent Logic)
*   [ ] **Rust Core & FFI:** Setup `flutter_rust_bridge` and integrate `vibe-kanban` submodules.
    *   **Test:** FFI bridge integration tests; verify Rust functions are callable from Dart with complex types.
*   [ ] **Worktree & Execution:** 
    *   [ ] Implement `WorktreeManager` for isolated task environments.
        *   **Test:** Unit tests for git worktree creation, isolation (file collision checks), and cleanup.
    *   [ ] Implement `CommandExecutor` for robust shell/tool execution.
        *   **Test:** Execute safe vs. unsafe commands; verify stdout/stderr capture and exit code handling.
*   [ ] **Capability Exploration:** Build the autonomous system scanner and Markdown synthesis engine.
    *   **Test:** Mock system environment tests; verify scanner correctly identifies tools (git, rustc) and hardware.
*   [ ] **Local Orchestration:** Implement the internal sub-task planner and resume logic.
    *   **Test:** State persistence tests; simulate a process crash and verify the agent resumes from the last log entry.

### Phase 4: Agent Client UI & Integration
*   [ ] **Client Frontend:** Build the minimalist operator dashboard using `design/ui/v1/app/agent/`.
    *   **Test:** Golden tests for the dashboard and capability explorer screens.
*   [ ] **The Log Stream:** Implement the real-time terminal output for Chain-of-Thought visualization.
    *   **Test:** Stress test with high-frequency log updates (>100 lines/sec) to ensure UI performance.
*   [ ] **HQ Synchronization:** Ensure real-time task pulling and progress reporting via the MSP Layer.
    *   **Test:** Round-trip integration test: HQ creates task -> Client pulls -> Client updates -> HQ displays update.

### Phase 5: Advanced AI & Agentic Workflows
*   [ ] **The Oracle & Architect Personas:**
    *   [ ] Implement LLM-based task interpretation and decomposition logic in HQ.
        *   **Test:** Prompt regression tests (evals); verify the Architect correctly breaks down 5 standard requests into valid sub-tasks.
    *   [ ] Build the Architect's "Validation & Nudge" loop with refined task descriptions.
        *   **Test:** Rejection flow test: simulate a failed task and verify the Architect appends feedback and updates the description.
*   [ ] **AI Coding Agent:** 
    *   [ ] Integrate `vibe-kanban/file_ranker` for RAG-based context retrieval.
        *   **Test:** RAG accuracy tests; verify the ranker returns the most relevant files for a given bug description.
    *   [ ] Implement the MCP Task Server for standardized tool access.
        *   **Test:** MCP protocol compliance tests; verify the model can successfully list and read files via MCP tools.
    *   [ ] Setup `DiffStream` for real-time code change visualization in HQ.
        *   **Test:** Verify diffs are correctly patched and rendered in the HQ UI in real-time.

### Phase 6: Physical World (Sentinel Integration)
*   [ ] **Hardware Drivers:** Implement USB/ADB/Serial interfacing in the Rust core.
    *   **Test:** Integration tests with physical/emulated hardware; verify serial data read/write integrity.
*   [ ] **Sentinel Dashboard:** Add physical status indicators to the Client UI.
    *   **Test:** Hardware disconnect simulation; verify UI reflects "Offline" status immediately.
*   [ ] **Remote Monitoring:** Enable real-time video/status streaming for physical tasks.
    *   **Test:** WebRTC/Stream latency tests; target <500ms for remote visual feedback.

---

## 9. Testing Strategy

### 9.1 Multi-Layered Validation
*   **Level 1: Unit & Logic (Rust/Dart):** Focused on individual functions, MSP implementations, and state management.
*   **Level 2: Visual & UX (Golden Tests):** Ensures the Brutalist-Refined aesthetic remains consistent across platforms and screen sizes.
*   **Level 3: Integration (FFI/MSP):** Validates the boundary between Flutter and Rust, and between the Application and Appwrite.
*   **Level 4: Agentic Evals (LLM):** Uses a set of "Prophecy Benchmarks" to ensure the Oracle and Architect personas remain accurate and reliable.

---

## 10. Development Environment

### 10.1 Appwrite Configuration
*   **Local Development:** Developers are encouraged to use a local Appwrite instance running in **Docker** for rapid iteration and offline development.
    *   Command: `docker compose up -d` (using the official Appwrite `docker-compose.yml`).
*   **Environment Variables:** Sensitive configuration and project keys must be managed via a `.env` file at the root of the HQ and Agent Client projects.
    *   **`.env` Template:**
        ```env
        APPWRITE_ENDPOINT=http://localhost/v1 # or cloud endpoint
        APPWRITE_PROJECT_ID=matrix_dev
        APPWRITE_API_KEY=your_dev_key_here
        ```
*   **Security Note:** The `.env` file is strictly for local development and must never be committed to source control. A `.env.example` should be provided as a reference.

### 10.2 Tooling
*   **Flutter:** Stable channel, latest version.
*   **Rust:** `rustup` with the latest stable toolchain.
*   **FFI:** `flutter_rust_bridge` codegen must be run after any changes to the Rust core logic.
