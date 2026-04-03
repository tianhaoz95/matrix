use anyhow::Result;
use executors::command::CommandBuilder;
use tokio::process::Command;

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

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
