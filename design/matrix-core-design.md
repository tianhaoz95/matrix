# Matrix: Asynchronous Multi-Agent Autonomous Organization

## 1. Project Vision
Matrix is an AI-first, fully autonomous organization inspired by the social structure of *The Matrix*. It enables a decentralized network of specialized AI agents to collaborate on complex tasks, bridging the digital and physical worlds.

The system is designed for **asynchronous autonomy**: humans provide high-level intent, and the organization (HQ + Agents) decomposes, executes, and validates the work without constant human oversight.

---

## 2. System Architecture

### 2.1 Component Overview
*   **The HQ (Headquarters):** The central nervous system. A persistent backend and management dashboard.
*   **The Agent Clients:** Distributed compute nodes running specialized AI personas. Each client is a self-contained unit capable of local orchestration.

### 2.2 Roles & Personas
| Role | Count | Responsibility |
| :--- | :--- | :--- |
| **The Architect** | 1 | Strategic lead. Task decomposition, resource allocation, and final quality assurance. |
| **The Oracle** | 1 | Human-AI bridge. Translates human "prophecies" (intents) into technical requirements and summarizes organizational progress for humans. |
| **Agent** | N | Digital specialist. Handles code development, security auditing, documentation, and CI/CD. |
| **Sentinel** | N | Physical interface. Manages hardware, IoT devices, robot arms, or mobile device testing. |

---

## 3. Tech Stack

### 3.1 The HQ (Headquarters)
*   **Frontend:** **Flutter (Web/Desktop/Mobile)**. Target platforms: Web, macOS, Windows, Linux, iOS, and Android.
*   **Backend-as-a-Service:** **Appwrite**.
    *   **Auth:** Multi-tenant authentication. Users can sign up and sign in.
    *   **Workspaces:** Modeled using Appwrite **Teams**. Each user can create or join multiple workspaces.
    *   **Database:** Task management, agent registry, and audit logs, all scoped to specific `workspace_id`s.
    *   **Realtime:** WebSocket-based synchronization for task updates and agent status within the active workspace.
    *   **Storage:** Hosting build artifacts and logs, partitioned by workspace.

### 3.2 The Agent Client
*   **Frontend/Controller:** **Flutter (Desktop/Android/iOS)**.
*   **Authentication & Connection:**
    *   **User Sign-In:** The agent client requires the user to sign in using the same credentials as the HQ.
    *   **Workspace Selection:** Upon sign-in, the user selects the workspace the agent should join.
    *   **Secure Session:** Uses Appwrite's session management to maintain a persistent, secure connection to the HQ.
*   **Core Logic:** **Rust** (integrated via `flutter_rust_bridge`). Handles high-performance tasks:
    *   **Local Orchestration:** Planning sub-tasks, managing local state, and executing tool calls (shell, file system, hardware).
    *   **LLM Interface:** Integration with remote APIs (OpenAI, Anthropic, Gemini) or **optional** local LLM orchestration (via `llama-cpp` or `candle`) for offline/private tasks.
    *   **File System & Process Management:** Securely managing the local workspace and build processes.
    *   **Hardware Interfacing:** For Sentinels (USB/Serial/Bluetooth/ADB).
*   **Networking:** Appwrite Dart/Rust SDKs for realtime sync with HQ.

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
*   **The Log Stream:** Realtime terminal-like output showing the agent's internal thought process (Chain-of-Thought).
*   **Physical Feedback (Sentinel Only):** Visual indicators of connected hardware status.

---

## 5. Agentic Loop & Autonomous Workflow

### 5.1 The "Prophecy" Loop (Workflow)
1.  **Intent Reception:** A human provides a high-level goal in HQ.
2.  **Oracle Interpretation:** The Oracle translates the goal into a structured "Project Brief" and alerts the Architect.
3.  **Architect Decomposition:** The Architect breaks the Brief into granular `tasks` in the Appwrite Database.
4.  **Capability Matching:** The Architect scans the `Capability Statements` of connected Agents/Sentinels.
5.  **Task Assignment:** Tasks are tagged with specific agent IDs or role requirements.
6.  **Autonomous Execution & Orchestration:**
    *   Agents/Sentinels pull tasks via Appwrite Realtime.
    *   **Local Decomposition:** The Agent Client's core logic (Rust) analyzes the assigned task and creates a local plan (sub-tasks).
    *   **Execution:** The Agent works through sub-tasks (coding, testing, physical manipulation), orchestrating its local environment.
    *   **Reporting:** It updates the task in HQ with granular progress reports, logs, and artifacts.
7.  **Quality Assurance:** The Architect reviews completed tasks. If failed, it re-assigns with feedback.
8.  **Final Summary:** Once the goal is reached, the Oracle generates a "Human Report" for the supervisor.

### 5.2 Capability Statements
Every agent client publishes a `capability.md` to HQ. 
*   **Example (Sentinel):** "I have access to a Pixel 8 Pro via ADB. I can install APKs and run UI tests."
*   **Example (Agent):** "I am specialized in Rust development and SQLite optimization. I have 32GB RAM for local builds."

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
