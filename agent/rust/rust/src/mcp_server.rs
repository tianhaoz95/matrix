use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use axum::{
    extract::State,
    response::sse::{Event, Sse},
    routing::{get, post},
    Json, Router,
};
use futures_util::stream::Stream;
use serde::{Deserialize, Serialize};
use tokio::sync::{mpsc, broadcast};
use tokio_stream::wrappers::ReceiverStream;
use uuid::Uuid;
use tracing::{info, error};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpMessage {
    pub jsonrpc: String,
    pub method: Option<String>,
    pub params: Option<serde_json::Value>,
    pub id: Option<serde_json::Value>,
    pub result: Option<serde_json::Value>,
    pub error: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskUpdateEvent {
    pub task_id: String,
    pub status: Option<String>,
    pub assigned_to: Option<String>,
    pub report: Option<String>,
}

pub struct AgentSession {
    pub id: String,
    pub tx: mpsc::Sender<Result<Event, std::convert::Infallible>>,
}

pub struct ServerState {
    pub sessions: Mutex<HashMap<String, Arc<AgentSession>>>,
    pub task_update_tx: broadcast::Sender<TaskUpdateEvent>,
}

pub async fn start_mcp_server(port: u16, task_update_tx: broadcast::Sender<TaskUpdateEvent>) -> anyhow::Result<()> {
    let state = Arc::new(ServerState {
        sessions: Mutex::new(HashMap::new()),
        task_update_tx,
    });

    let app = Router::new()
        .route("/sse", get(sse_handler))
        .route("/messages", post(messages_handler))
        .with_state(state);

    let addr = format!("0.0.0.0:{}", port);
    info!("Starting MCP SSE Server on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

async fn sse_handler(
    State(state): State<Arc<ServerState>>,
) -> Sse<impl Stream<Item = Result<Event, std::convert::Infallible>>> {
    let session_id = Uuid::new_v4().to_string();
    let (tx, rx) = mpsc::channel(100);

    let session = Arc::new(AgentSession {
        id: session_id.clone(),
        tx,
    });

    state.sessions.lock().unwrap().insert(session_id.clone(), session.clone());

    info!("New MCP session started: {}", session_id);

    // Send the endpoint event as per MCP spec
    let _ = session.tx.send(Ok(Event::default()
        .event("endpoint")
        .data(format!("/messages?session_id={}", session_id)))).await;

    let stream = ReceiverStream::new(rx);
    Sse::new(stream)
}

#[derive(Debug, Deserialize)]
struct MessagesQuery {
    session_id: String,
}

async fn messages_handler(
    State(state): State<Arc<ServerState>>,
    axum::extract::Query(query): axum::extract::Query<MessagesQuery>,
    Json(msg): Json<McpMessage>,
) -> Json<serde_json::Value> {
    info!("Received message from {}: {:?}", query.session_id, msg);

    // Standard MCP Tool Dispatching
    if let Some(method) = &msg.method {
        match method.as_str() {
            "initialize" => {
                return Json(serde_json::json!({
                    "jsonrpc": "2.0",
                    "id": msg.id,
                    "result": {
                        "protocolVersion": "2024-11-05",
                        "capabilities": {
                            "tools": {}
                        },
                        "serverInfo": {
                            "name": "matrix-core",
                            "version": "0.1.0"
                        }
                    }
                }));
            }
            "tools/list" => {
                return Json(serde_json::json!({
                    "jsonrpc": "2.0",
                    "id": msg.id,
                    "result": {
                        "tools": [
                            {
                                "name": "matrix_clone",
                                "description": "Clone a git repository",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "url": { "type": "string" },
                                        "path": { "type": "string" }
                                    },
                                    "required": ["url", "path"]
                                }
                            },
                            {
                                "name": "matrix_worktree",
                                "description": "Create an isolated git worktree",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "repo_path": { "type": "string" },
                                        "branch_name": { "type": "string" },
                                        "target_path": { "type": "string" }
                                    },
                                    "required": ["repo_path", "branch_name", "target_path"]
                                }
                            },
                            {
                                "name": "matrix_update_task",
                                "description": "Update task status and report in HQ",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {
                                        "task_id": { "type": "string" },
                                        "status": { "type": "string" },
                                        "assigned_to": { "type": "string" },
                                        "report": { "type": "string" }
                                    },
                                    "required": ["task_id"]
                                }
                            }
                        ]
                    }
                }));
            }
            "tools/call" => {
                if let Some(params) = msg.params {
                    let tool_name = params.get("name").and_then(|v| v.as_str()).unwrap_or("");
                    let tool_args = params.get("arguments").cloned().unwrap_or(serde_json::json!({}));
                    
                    let result = handle_tool_call(&state, tool_name, tool_args).await;
                    
                    return Json(serde_json::json!({
                        "jsonrpc": "2.0",
                        "id": msg.id,
                        "result": {
                            "content": [
                                {
                                    "type": "text",
                                    "text": result
                                }
                            ]
                        }
                    }));
                }
            }
            _ => {
                error!("Unknown method: {}", method);
            }
        }
    }

    Json(serde_json::json!({
        "jsonrpc": "2.0",
        "id": msg.id,
        "result": {}
    }))
}

async fn handle_tool_call(state: &ServerState, name: &str, args: serde_json::Value) -> String {
    match name {
        "matrix_clone" => {
            let url = args.get("url").and_then(|v| v.as_str()).unwrap_or("");
            let path = args.get("path").and_then(|v| v.as_str()).unwrap_or("");
            crate::api::simple::clone_repository(url.to_string(), path.to_string()).await
        }
        "matrix_worktree" => {
            let repo = args.get("repo_path").and_then(|v| v.as_str()).unwrap_or("");
            let branch = args.get("branch_name").and_then(|v| v.as_str()).unwrap_or("");
            let path = args.get("target_path").and_then(|v| v.as_str()).unwrap_or("");
            crate::api::simple::create_agent_worktree(repo.to_string(), branch.to_string(), path.to_string()).await
        }
        "matrix_update_task" => {
            let task_id = args.get("task_id").and_then(|v| v.as_str()).unwrap_or("");
            let status = args.get("status").and_then(|v| v.as_str()).map(|s| s.to_string());
            let assigned_to = args.get("assigned_to").and_then(|v| v.as_str()).map(|s| s.to_string());
            let report = args.get("report").and_then(|v| v.as_str()).map(|s| s.to_string());
            
            let event = TaskUpdateEvent {
                task_id: task_id.to_string(),
                status,
                assigned_to,
                report,
            };
            
            match state.task_update_tx.send(event) {
                Ok(_) => "Task update signal sent to HQ bridge".to_string(),
                Err(e) => format!("Failed to send task update: {}", e),
            }
        }
        _ => format!("Tool not found: {}", name),
    }
}
