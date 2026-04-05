# Design: Matrix Agent Prompt for Gemini CLI (MCP SSE Edition)

## 1. Objective
Design a robust, multi-step prompt for the `gemini-cli` that enables a Matrix Agent Client to autonomously claim, execute, verify, and report on tasks using the **Singleton MCP SSE Server**.

## 2. Agent Identity & Context
The agent operates as a specialized unit within the Matrix Organization. It connects to a persistent **Matrix Hub** (Rust Core) via SSE to access system tools.

---

## 3. The Autonomous Workflow (MCP Driven)

### Phase 1: Task Acquisition & Validation
1.  **Analyze Task**: Evaluate requirements vs. local capabilities.
2.  **Claim Task**: Use `matrix_update_task` tool to set `assigned_to` and `status: in_progress`.
    *   *Constraint*: Abort if already assigned.

### Phase 2: Environment Setup
1.  **Isolate**: If `repository_url` is present, use `matrix_worktree`.
2.  **Explore**: Use standard file tools (or `matrix_ls_r`) to understand the codebase.

### Phase 3: Execution
1.  **Iterate**: Use shell tools to implement features.
2.  **Self-Correct**: Fix compiler errors or test failures autonomously.

### Phase 4: Reporting
1.  **Technical Report**: Synthesize work into a Markdown report.
2.  **Handoff**: Use `matrix_update_task` to set `status: validation` and attach the report.

---

## 4. The Master Prompt Template

```markdown
You are a Matrix Autonomous Agent. You are connected to the Matrix Hub MCP server.
Your mission is to fulfill the task provided below.

### MISSION PARAMETERS
- **Task ID**: {{TASK_ID}}
- **Task Content**:
{{TASK_CONTENT}}

### OPERATIONAL PROTOCOL
1. **CLAIM**: Immediately call `matrix_update_task` with your Agent ID and `status: "In Progress"`.
2. **SETUP**: Use `matrix_worktree` if a repository is required.
3. **EXECUTE**: Perform the requested changes. 
4. **VERIFY**: Run tests to ensure high-quality output.
5. **REPORT**: Call `matrix_update_task` with `status: "Validation"` and a detailed Markdown report of your changes.

### AVAILABLE MATRIX TOOLS
- `matrix_clone(url, path)`: Clone a repo.
- `matrix_worktree(repo_path, branch_name, target_path)`: Setup isolation.
- `matrix_update_task(task_id, status, assigned_to, report)`: Sync with HQ.

BEGIN MISSION.
```

---

## 5. Integration in `./agent`

The Flutter client will:
1.  Ensure the SSE server is running on `localhost:8000`.
2.  Write `.gemini/settings.json` pointing to `http://localhost:8000/sse`.
3.  Invoke `gemini --yolo -p "$PROMPT"`.
4.  The Rust core will intercept `matrix_update_task` calls and emit events back to Flutter.
5.  Flutter will then perform the real Appwrite calls to update the HQ database.
