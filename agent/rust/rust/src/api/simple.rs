use anyhow::Result;
use tokio::io::AsyncBufReadExt;
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

pub async fn execute_command(cmd: String, sink: StreamSink<String>) -> Result<()> {
    let builder = CommandBuilder::new(cmd);
    let parts = builder.build_initial()?;
    let (program, args) = parts.into_resolved().await?;

    let mut child = Command::new(program)
        .args(args)
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()?;

    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();

    let mut stdout_reader = tokio::io::BufReader::new(stdout).lines();
    let mut stderr_reader = tokio::io::BufReader::new(stderr).lines();

    let sink_clone = sink.clone();
    tokio::spawn(async move {
        while let Ok(Some(line)) = stdout_reader.next_line().await {
            let _ = sink_clone.add(line);
        }
    });

    let sink_clone2 = sink.clone();
    tokio::spawn(async move {
        while let Ok(Some(line)) = stderr_reader.next_line().await {
            let _ = sink_clone2.add(format!("ERR: {}", line));
        }
    });

    let status = child.wait().await?;
    let _ = sink.add(format!("Process finished with status: {}", status));
    
    Ok(())
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct HardwareDevice {
    pub id: String,
    pub name: String,
    pub connection_type: String, // "ADB", "USB", "Network"
    pub status: String,          // "Online", "Offline", "Unauthorized"
}

pub async fn list_hardware_devices() -> Vec<HardwareDevice> {
    let mut devices = Vec::new();

    // 1. ADB Devices
    if let Ok(output) = Command::new("adb").arg("devices").output().await {
        let s = String::from_utf8_lossy(&output.stdout);
        for line in s.lines().skip(1) {
            if !line.trim().is_empty() {
                let parts: Vec<&str> = line.split_whitespace().collect();
                if parts.len() >= 2 {
                    devices.push(HardwareDevice {
                        id: parts[0].to_string(),
                        name: format!("Android Device ({})", parts[0]),
                        connection_type: "ADB".to_string(),
                        status: parts[1].to_string(),
                    });
                }
            }
        }
    }

    // 2. USB Devices (Linux specific)
    #[cfg(target_os = "linux")]
    {
        if let Ok(output) = Command::new("lsusb").output().await {
            let s = String::from_utf8_lossy(&output.stdout);
            for line in s.lines() {
                if !line.trim().is_empty() {
                    devices.push(HardwareDevice {
                        id: line[4..13].trim().to_string(), // Extract Bus/Device IDs
                        name: line[33..].trim().to_string(), // Extract Manufacturer/Product
                        connection_type: "USB".to_string(),
                        status: "Connected".to_string(),
                    });
                }
            }
        }
    }

    devices
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

pub async fn generate_codebase_map(path: String) -> String {
    let root = Path::new(&path);
    let mut map = Vec::new();
    map.push(format!("# Codebase Map: {}", path));

    // 1. Project Type Detection
    let mut project_types = Vec::new();
    if root.join("pubspec.yaml").exists() { project_types.push("Flutter/Dart"); }
    if root.join("Cargo.toml").exists() { project_types.push("Rust"); }
    if root.join("package.json").exists() { project_types.push("Node.js/TypeScript"); }
    if root.join("requirements.txt").exists() || root.join("pyproject.toml").exists() { project_types.push("Python"); }
    
    map.push(format!("**Detected Stack**: {}", project_types.join(", ")));
    map.push("\n## Key Files".to_string());

    // 2. Identify Entry Points & Configs
    let important_patterns = [
        "lib/main.dart",
        "src/main.rs",
        "src/lib.rs",
        "src/index.ts",
        "src/app.py",
        "pubspec.yaml",
        "Cargo.toml",
        "package.json",
        "AndroidManifest.xml",
        "README.md",
    ];

    for pattern in important_patterns {
        let p = root.join(pattern);
        if p.exists() {
            map.push(format!("- `{}`: Identified as a key entry/config file.", pattern));
        }
    }

    // 3. Structure Summary (Top level dirs)
    map.push("\n## Directory Structure".to_string());
    if let Ok(entries) = fs::read_dir(root) {
        for entry in entries.flatten() {
            if let Ok(ft) = entry.file_type() {
                if ft.is_dir() {
                    let name = entry.file_name().to_string_lossy().to_string();
                    if !workspace_utils::path::ALWAYS_SKIP_DIRS.contains(&name.as_str()) {
                        map.push(format!("- `{}/`: Directory", name));
                    }
                }
            }
        }
    }

    map.join("\n")
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
    let mut agent = configs.get_coding_agent_or_default(&profile_id);
    
    // Ensure YOLO is enabled if using Gemini CLI for autonomy
    if let MatrixAIProvider::Gemini = provider {
        if let CodingAgent::Gemini(ref mut g) = agent {
            g.yolo = Some(true);
        }
    }

    let env = ExecutionEnv::new(RepoContext::default(), false, String::new());
    let path = Path::new(&working_dir);

    tracing::info!("Spawning agent task in {}", working_dir);

    match agent.spawn(path, &prompt, &env).await {
        Ok(mut spawned) => {
            match spawned.child.wait().await {
                Ok(status) => {
                    if status.success() {
                        format!("Agent finished successfully")
                    } else {
                        format!("Agent finished with error status: {}", status)
                    }
                },
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
