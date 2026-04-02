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
*   **Frontend:** **Flutter (Web/Desktop)**. Chosen for its rich UI capabilities and multi-platform consistency.
*   **Backend-as-a-Service:** **Appwrite**.
    *   **Database:** Task management, agent registry, and audit logs.
    *   **Realtime:** WebSocket-based synchronization for task updates and agent status.
    *   **Auth:** Secure access for human supervisors and agent client authentication.
    *   **Storage:** Hosting build artifacts, logs, and shared resources.

### 3.2 The Agent Client
*   **Frontend/Controller:** **Flutter (Desktop/Android/iOS)**. Provides a local UI for monitoring resource usage and agent state.
*   **Core Logic:** **Rust** (integrated via `flutter_rust_bridge`). Handles high-performance tasks:
    *   Local LLM orchestration (via `llama-cpp` or `candle`).
    *   File system operations and process management.
    *   Hardware interfacing for Sentinels (USB/Serial/Bluetooth).
*   **Networking:** Appwrite Dart/Rust SDKs for realtime sync with HQ.

---

## 4. UI/UX Design

### 4.1 HQ: The Command Center
*   **Aesthetic:** *Brutalist-Refined*. A dark, high-contrast theme (Matrix Green/Deep Gray) with clean typography (JetBrains Mono/Inter).
*   **The Oracle's Feed:** A prominent top-level summary. Uses "Human-Centric NLP" to explain what the organization is doing *right now*.
*   **The Matrix (Kanban):** A multi-lane board tracking tasks: `Backlog`, `Architect Review`, `In Progress`, `Validation`, `Complete`.
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
6.  **Autonomous Execution:**
    *   Agents/Sentinels pull tasks via Appwrite Realtime.
    *   They work locally (coding, testing, physical manipulation).
    *   They update the task in HQ with progress reports and artifacts.
7.  **Quality Assurance:** The Architect reviews completed tasks. If failed, it re-assigns with feedback.
8.  **Final Summary:** Once the goal is reached, the Oracle generates a "Human Report" for the supervisor.

### 5.2 Capability Statements
Every agent client publishes a `capability.md` to HQ. 
*   **Example (Sentinel):** "I have access to a Pixel 8 Pro via ADB. I can install APKs and run UI tests."
*   **Example (Agent):** "I am specialized in Rust development and SQLite optimization. I have 32GB RAM for local builds."

---

## 6. Data Model (Appwrite Collections)

*   **`agents`**: `id`, `name`, `role`, `status` (online/offline/busy), `capability_statement` (string/link).
*   **`tasks`**: `id`, `title`, `description`, `assigned_to`, `status`, `priority`, `parent_task_id`, `artifacts` (array of links).
*   **`messages`**: `id`, `sender_id`, `content`, `timestamp`, `thread_id` (for agent-to-agent communication).
*   **`logs`**: Detailed execution history for auditability.

---

## 7. Security & Ethics
*   **Sandboxing:** Agents execute code in local Docker containers or isolated environments managed by the Rust core.
*   **Human-in-the-Loop:** The Oracle can pause the entire organization if it detects "Anomalies" or safety violations.
*   **Audit Trails:** Every action taken by an AI agent is immutable and logged in Appwrite.
