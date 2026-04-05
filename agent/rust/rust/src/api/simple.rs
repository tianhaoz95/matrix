use anyhow::Result;
use executors::command::CommandBuilder;
use tokio::process::Command;
use std::path::{Path, PathBuf};
use git::GitService;
use worktree_manager::WorktreeManager;
use std::fs;
use crate::frb_generated::StreamSink;
use tokio::sync::broadcast;
use crate::mcp_server::TaskUpdateEvent;
use executors::executors::{CodingAgent, StandardCodingAgentExecutor, BaseCodingAgent};
use executors::env::{ExecutionEnv, RepoContext};
use executors::profile::{ExecutorConfigs, ExecutorProfileId};

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

pub async fn execute_command(cmd: String) -> String {
    match run_command_internal(cmd).await {
        Ok(output) => output,
        Err(e) => format!("Error: {}", e),
    }
}

pub async fn scan_system() -> String {
    let mut capabilities = Vec::new();
    capabilities.push("# System Capability Report".to_string());

    let tools = ["git", "adb", "flutter", "rustc", "python3", "docker", "gcc"];
    for tool in tools {
        if let Some(path) = workspace_utils::shell::resolve_executable_path(tool).await {
            capabilities.push(format!("- **{}**: Found at {:?}", tool, path));
        }
    }

    capabilities.join("\n")
}

pub async fn automatic_capability_check() -> String {
    let mut report = Vec::new();
    report.push("# Automatic Capability Check".to_string());

    // Check Flutter
    report.push("## Flutter Status".to_string());
    match run_command_internal("flutter doctor -v".to_string()).await {
        Ok(output) => {
            if output.contains("Flutter") && output.contains("Tools") {
                report.push("- **Flutter**: AVAILABLE".to_string());
            } else {
                report.push("- **Flutter**: MISSING OR ERRONEOUS".to_string());
            }
            report.push("\n### Detailed Output".to_string());
            report.push(format!("```\n{}\n```", output));
        }
        Err(e) => {
            report.push(format!("- **Flutter**: ERROR ({})", e));
        }
    }

    // Check Android Devices
    report.push("\n## Android Device Status".to_string());
    match run_command_internal("adb devices".to_string()).await {
        Ok(output) => {
            let devices: Vec<&str> = output.lines().filter(|line| !line.is_empty() && !line.starts_with("List of devices")).collect();
            if devices.is_empty() {
                report.push("- **Android Devices**: NONE CONNECTED".to_string());
            } else {
                report.push(format!("- **Android Devices**: {} CONNECTED", devices.len()));
                for dev in devices {
                    report.push(format!("  - {}", dev));
                }
            }
        }
        Err(e) => {
            report.push(format!("- **Android Devices**: ERROR ({})", e));
        }
    }

    report.join("\n")
}

// --- Software Engineering Hands (Git & Worktrees) ---

pub async fn clone_repository(url: String, target_path: String) -> String {
    let url_clone = url.clone();
    let target_path_clone = target_path.clone();
    
    match tokio::task::spawn_blocking(move || {
        let repo_path = Path::new(&target_path_clone);
        GitService::clone_repository(&url_clone, &repo_path, None)
    }).await {
        Ok(Ok(_)) => format!("Successfully cloned {} to {}", url, target_path),
        Ok(Err(e)) => format!("Git error: {}", e),
        Err(e) => format!("Task error: {}", e),
    }
}

pub async fn create_agent_worktree(repo_path: String, branch_name: String, target_path: String) -> String {
    let repo_path_buf = PathBuf::from(&repo_path);
    let wt_path_buf = PathBuf::from(&target_path);
    
    match WorktreeManager::create_worktree(&repo_path_buf, &branch_name, &wt_path_buf, "main", true).await {
        Ok(_) => format!("Successfully created worktree for branch {} at {}", branch_name, target_path),
        Err(e) => format!("Worktree error: {}", e),
    }
}

pub fn list_files_recursive(path: String) -> Vec<String> {
    let mut files = Vec::new();
    if let Ok(entries) = fs::read_dir(path) {
        for entry in entries.flatten() {
            if let Ok(file_type) = entry.file_type() {
                if file_type.is_file() {
                    files.push(entry.path().to_string_lossy().to_string());
                } else if file_type.is_dir() {
                    let sub_files = list_files_recursive(entry.path().to_string_lossy().to_string());
                    files.extend(sub_files);
                }
            }
        }
    }
    files
}

// --- AI Agent Execution (Standardized) ---

pub enum MatrixAIProvider {
    Gemini,
    Claude,
    Codex,
}

pub async fn run_agent_task(provider: MatrixAIProvider, prompt: String, working_dir: String) -> String {
    let agent_type = match provider {
        MatrixAIProvider::Gemini => BaseCodingAgent::Gemini,
        MatrixAIProvider::Claude => BaseCodingAgent::ClaudeCode,
        MatrixAIProvider::Codex => BaseCodingAgent::Codex,
    };

    let configs = ExecutorConfigs::get_cached();
    let profile_id = ExecutorProfileId::new(agent_type);
    let agent = configs.get_coding_agent_or_default(&profile_id);
    
    let env = ExecutionEnv::new(RepoContext::default(), false, String::new());
    let path = Path::new(&working_dir);

    match agent.spawn(path, &prompt, &env).await {
        Ok(mut spawned) => {
            match spawned.child.wait().await {
                Ok(status) => format!("Agent finished with status: {}", status),
                Err(e) => format!("Agent execution error: {}", e),
            }
        },
        Err(e) => format!("Failed to spawn agent: {}", e),
    }
}

async fn run_command_internal(cmd: String) -> Result<String> {
    let builder = CommandBuilder::new(cmd);
    let parts = builder.build_initial()?;
    let (program, args) = parts.into_resolved().await?;

    let output = Command::new(program)
        .args(args)
        .output()
        .await?;

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();

    if output.status.success() {
        Ok(stdout)
    } else {
        Ok(format!("Command failed with status {}:\n{}", output.status, stderr))
    }
}

// --- MCP SSE Server ---

lazy_static::lazy_static! {
    static ref TASK_UPDATE_TX: broadcast::Sender<TaskUpdateEvent> = {
        let (tx, _) = broadcast::channel(100);
        tx
    };
}

pub async fn start_mcp_server(port: u16) -> String {
    let tx = TASK_UPDATE_TX.clone();
    match crate::mcp_server::start_mcp_server(port, tx).await {
        Ok(_) => "Server stopped successfully".to_string(),
        Err(e) => format!("Server error: {}", e),
    }
}

pub async fn listen_mcp_events(sink: StreamSink<TaskUpdateEvent>) -> Result<()> {
    let mut rx = TASK_UPDATE_TX.subscribe();
    while let Ok(event) = rx.recv().await {
        sink.add(event).map_err(|e| anyhow::anyhow!("Sink error: {}", e))?;
    }
    Ok(())
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[tokio::test]
    async fn test_worktree_flow() {
        let td = TempDir::new().unwrap();
        let repo_path = td.path().join("repo");
        
        // Initialize a dummy repo
        let git_service = GitService::new();
        git_service.initialize_repo_with_main_branch(&repo_path).unwrap();
        
        let wt_path = td.path().join("wt");
        let res = create_agent_worktree(
            repo_path.to_string_lossy().to_string(),
            "feature-test".to_string(),
            wt_path.to_string_lossy().to_string()
        ).await;
        
        assert!(res.contains("Successfully created worktree"));
        assert!(wt_path.exists());
    }
}
