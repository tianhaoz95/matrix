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

## 3. Tech Stack & Abstraction Layer

### 3.0 The MSP Abstraction Layer
The Matrix utilizes a dependency injection pattern to interact with backend services. Core interfaces (Providers) are defined in both Flutter (Dart) and Rust:

*   **`IAuthProvider`**: Handles signup, login, session persistence, and workspace (team) management.
*   **`IDataProvider`**: Handles CRUD operations and Realtime event subscriptions for all collections (Tasks, Agents, Logs).
*   **`IStorageProvider`**: Handles file uploads (artifacts, logs) and retrieval.

### 3.1 Primary Implementation: Appwrite
The reference implementation uses **Appwrite** as the service provider.
*   **Frontend:** **Flutter (Web/Desktop/Mobile)**.
*   **Backend-as-a-Service:**
    *   **Auth:** Implements `IAuthProvider` using Appwrite Auth and Teams.
    *   **Database:** Implements `IDataProvider` using Appwrite Databases.
    *   **Realtime:** Uses Appwrite Realtime for WebSocket synchronization.
    *   **Storage:** Implements `IStorageProvider` using Appwrite Buckets.

### 3.2 The Agent Client
*   **Frontend/Controller:** **Flutter (Desktop/Android/iOS)**.
*   **Authentication & Connection:**
    *   **User Sign-In:** The agent client uses the `IAuthProvider` to sign in.
    *   **Workspace Selection:** Upon sign-in, the user selects the workspace the agent should join via the MSP.
    *   **Secure Session:** The MSP manages the secure, persistent session.
*   **Core Logic:** **Rust** (integrated via `flutter_rust_bridge`). Handles high-performance tasks utilizing optimized libraries:
    *   **Git Worktree Management:** Powered by `vibe-kanban/worktree-manager`, enabling agents to work on isolated feature branches without polluting the main workspace.
    *   **Task Execution:** Powered by `vibe-kanban/executors`, providing a unified interface for running shell commands, managing environment variables, and capturing execution logs.
    *   **Local Orchestration:** Planning sub-tasks, managing local state, and executing tool calls (shell, file system, hardware).
    *   **LLM Interface:** Integration with remote APIs (OpenAI, Anthropic, Gemini) or **optional** local LLM orchestration (via `llama-cpp` or `candle`) for offline/private tasks.
    *   **System Exploration:** Autonomous discovery of local tools (git, compilers, ADB), hardware (USB devices, GPUs), and system resources (RAM, CPU) to generate capability reports.
    *   **File System & Process Management:** Securely managing the local workspace and build processes.
    *   **Hardware Interfacing:** For Sentinels (USB/Serial/Bluetooth/ADB).
*   **Networking:** The client communicates via the **MSP Layer**, utilizing the active implementation (e.g., Appwrite Dart/Rust SDKs).

---

## 4. UI/UX Design

### 4.0 Authentication & Onboarding
*   **The Matrix Entry:** A themed login/signup interface ("The Construct").
*   **Workspace Selector:** After authentication, a clean interface allows users to select an existing workspace or "Initialize a New Simulation" (create a new workspace).

### 4.1 HQ: The Command Center
*   **Aesthetic:** *Brutalist-Refined*. A dark, high-contrast theme (Matrix Green/Deep Gray) with clean typography (JetBrains Mono/Inter).
*   **Responsive Multi-Platform Layout:** 
    *   **Desktop/Web:** A multi-pane dashboard with persistent sidebars for navigation and agent status.
    *   **Mobile:** A tab-based or bottom-navigation interface focusing on the Oracle's Feed and active task tracking, with collapsible "drawers" for the Agent Registry.
*   **The Oracle's Feed:** A prominent top-level summary. Uses "Human-Centric NLP" to explain what the organization is doing *right now*.
*   **The Matrix (Kanban):** A multi-lane board tracking tasks: `Backlog`, `Architect Review`, `In Progress`, `Validation`, `Complete`. (Transitions to a vertical list-view on mobile).
*   **Agent Registry:** A sidebar showing connected clients, their roles, and their "Capability Statements" (Markdown-based skill descriptions).

### 4.2 Client: The Operator Interface
*   **Minimalist Dashboard:** Focused on throughput and local environment health.
*   **Capability Explorer:** A dedicated screen to initiate "System Scans." Displays a Markdown preview of discovered capabilities for user modification and approval.
*   **The Log Stream:** Realtime terminal-like output showing the agent's internal thought process (Chain-of-Thought).
*   **Physical Feedback (Sentinel Only):** Visual indicators of connected hardware status.

---

## 5. Agentic Loop & Autonomous Workflow

### 5.1 The "Prophecy" Loop (File-Centric Workflow)
All communication and task management in the Matrix are driven by **Markdown Documents with YAML Front Matter**, utilizing an optimized agentic loop inspired by high-performance autonomous systems.

1.  **Intent Reception (The Prophecy):** A human creates a "Request" document in HQ.
    *   `status: draft`
    *   `responsible_party: the_oracle`
2.  **Oracle Interpretation & Pre-fetching:** 
    *   The Oracle translates the intent and initiates **Background Capability Pre-fetching**. 
    *   It scans for relevant Agent/Sentinel `capability.md` files while the Architect is being alerted.
    *   `status: interpreted`
    *   `responsible_party: the_architect`
3.  **Architect Decomposition:** The Architect analyzes the Request and pre-fetched data to generate granular "Task" documents.
    *   `status: pending`
    *   `dependencies: [task_id_1, task_id_2]`
4.  **Dependency & Token Budgeting:** 
    *   The Architect monitors task dependencies. A task is only marked `ready_for_execution` when all blockers are `completed`.
    *   **Token/Resource Guard:** The Architect tracks cumulative resource usage and may "nudge" or pause Agents if they exceed a workspace budget.
5.  **Autonomous Execution & Local Orchestration:**
    *   Agents/Sentinels scan for tasks where `status: ready_for_execution`.
    *   **Local Resume Logic:** If a task was previously interrupted (e.g., token limit reached), the Agent uses the most recent `Progress Logs` to resume mid-thought without re-planning the entire task.
    *   **Reporting:** The Agent updates the HQ Task document with progress logs in the Markdown body and status updates in the YAML.
6.  **Validation & Quality Assurance:** The Architect reviews the final Task output.
    *   **Automated Stop Hooks:** Before human review, the Architect may execute automated validation hooks (e.g., `npm test`, hardware checks).
    *   **Approval:** Marks task `completed`, unblocking dependent tasks.
    *   **Nudge-based Rejection:** If the output is insufficient, the Architect updates the front matter to `status: revision_needed` and provides a **Refinement Nudge**. Instead of a full restart, the Agent is instructed to focus specifically on the delta identified in the `# Review Feedback`.
    *   **Re-assignment:** If the Agent is unable to fulfill the task, the Architect resets it to `pending` with updated `capability_requirements`.
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

### 5.3 Capability Discovery & Synthesis
1.  **Authorization:** The user grants the Agent Client permission to scan the host system.
2.  **Autonomous Scan:** The Rust core logic runs a series of diagnostic tools (e.g., `which git`, `lscpu`, `adb devices`, `rustc --version`).
3.  **Synthesis:** The Agent Client (optionally using an LLM) compiles the raw diagnostic data into a human-readable and Architect-legible Markdown statement.
4.  **User Review:** The user can edit the synthesized statement in the Client UI (e.g., hiding certain tools or adding manual descriptions).
5.  **Synchronization:** Upon approval, the statement is pushed to the HQ via the MSP Layer and becomes visible to the Architect for task delegation.

---

## 6. Data Model (Appwrite Collections)

All collections are scoped by **Permissions** (User/Team-level access) and contain a `workspace_id` to ensure isolation.

*   **`workspaces` (Appwrite Teams)**: Built-in Appwrite Teams are used to manage membership.
*   **`agents`**: `id`, `workspace_id`, `name`, `role`, `status`, `capability_statement`.
*   **`tasks`**: `id`, `workspace_id`, `title`, `description`, `assigned_to`, `status`, `priority`, `parent_task_id`, `artifacts` (array of links).
*   **`messages`**: `id`, `workspace_id`, `sender_id`, `content`, `timestamp`, `thread_id`.
*   **`logs`**: `id`, `workspace_id`, `agent_id`, `content`, `timestamp`.

---

## 7. Security & Ethics
*   **Sandboxing:** Agents execute code in local Docker containers or isolated environments managed by the Rust core.
*   **Human-in-the-Loop:** The Oracle can pause the entire organization if it detects "Anomalies" or safety violations.
*   **Audit Trails:** Every action taken by an AI agent is immutable and logged in Appwrite.
