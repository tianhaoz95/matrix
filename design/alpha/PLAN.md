# Implementation Plan: Project Alpha (Unfinished Tasks)

Based on the roadmap in `design/matrix-core-design.md`, the following items are identified as unfinished and need to be implemented to fully realize the Matrix vision.

## Phase 3: Agent Client Core (The Sentinel/Agent Logic)
*   **Task 3.1: Worktree & Execution**
    *   **Subtask 3.1.1:** Implement `WorktreeManager` in the Rust core for isolated task environments.
    *   **Subtask 3.1.2:** Enhance `CommandExecutor` in the Rust core to capture detailed execution logs and status using `vibe-kanban/executors`.
    *   **Test:** Unit tests in Rust for git worktree creation and command execution.

## Phase 4: Agent Client UI & Integration
*   **Task 4.1: Agent Integration Tests**
    *   **Subtask 4.1.1:** Create `integration_test/app_test.dart` for the agent app.
    *   **Subtask 4.1.2:** Verify sign-in, navigation, and dashboard functionalities (Capability Explorer, Log Stream) on a connected Android device.
    *   **Test:** Run `flutter test integration_test/app_test.dart -d <android-device-id>` and ensure it passes.

## Phase 5: Advanced AI & Agentic Workflows
*   **Task 5.1: The Oracle & Architect Personas (HQ)**
    *   **Subtask 5.1.1:** Implement an LLM service provider in HQ (using `google_generative_ai` or similar) to handle "Prophecy" interpretation.
    *   **Subtask 5.1.2:** Implement the Architect's task decomposition logic, turning a high-level intent into `MatrixTask` subtasks in Appwrite.
    *   **Test:** Integration test verifying the Architect can process a draft request and output pending sub-tasks.
*   **Task 5.2: AI Coding Agent (Agent Client)**
    *   **Subtask 5.2.1:** Integrate an MCP Task Server or basic `file_ranker` logic in the Rust core to allow the agent to understand the codebase.
    *   **Subtask 5.2.2:** Update the autonomous loop to leverage the LLM for reasoning before executing commands.
    *   **Test:** Mock a task assignment and verify the agent makes correct reasoning steps in its Log Stream.

## Phase 6: Physical World (Sentinel Integration)
*   **Task 6.1: Hardware & Remote Monitoring**
    *   **Subtask 6.1.1:** Add basic USB/ADB device detection to the Rust `scan_system` capability. (Partially done, needs refinement).
    *   **Subtask 6.1.2:** Add physical status indicators to the Sentinel Dashboard.
    *   **Test:** Verify the UI reflects "Offline" or "Connected" status based on Rust hardware checks.

---
## Execution Strategy
1.  **Immediate:** Implement the `agent` integration tests (Task 4.1) to establish a baseline for both apps passing on Android.
2.  **Next:** Implement the `Oracle & Architect` personas in HQ (Task 5.1) to allow automatic task decomposition.
3.  **Then:** Implement the `WorktreeManager` and `AI Coding Agent` logic (Task 3.1 & 5.2) in the Agent Client to execute decomposed tasks.
4.  **Finally:** Refine Sentinel Integration (Task 6.1) and ensure all end-to-end tests pass.
