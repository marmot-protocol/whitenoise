//! Stream Rust/tracing logs to Flutter for display in app logs.

use crate::api::error::ApiError;
use crate::frb_generated::StreamSink;
use chrono::Utc;
use flutter_rust_bridge::frb;
use std::path::PathBuf;
use tokio::fs::File;
use tokio::io::{AsyncBufReadExt, AsyncSeekExt, BufReader};
use tokio::time::{Duration, interval};

/// Path to the current whitenoise log file.
/// Matches tracing_appender rolling: {logs_dir}/{dev|release}/whitenoise.{date}.log
fn rust_log_path(logs_base_dir: &str) -> PathBuf {
    let subdir = if cfg!(debug_assertions) {
        "dev"
    } else {
        "release"
    };
    let date = Utc::now().format("%Y-%m-%d");
    PathBuf::from(logs_base_dir)
        .join(subdir)
        .join(format!("whitenoise.{date}.log"))
}

/// Stream new lines from the Rust log file to Flutter.
/// Tails the whitenoise log file and emits each new line via the sink.
#[frb]
pub async fn subscribe_to_rust_logs(
    logs_base_dir: String,
    sink: StreamSink<String>,
) -> Result<(), ApiError> {
    let path = rust_log_path(&logs_base_dir);

    let mut file = loop {
        match File::open(&path).await {
            Ok(f) => break f,
            Err(e) => {
                let msg =
                    format!("subscribe_to_rust_logs: waiting for log file path={path:?} err={e}");
                if sink.add(msg).is_err() {
                    return Ok(());
                }
                tokio::time::sleep(Duration::from_secs(2)).await;
            }
        }
    };
    file.seek(std::io::SeekFrom::End(0)).await?;

    let mut reader = BufReader::new(file);
    let mut line = String::new();
    let mut poll = interval(Duration::from_millis(200));

    loop {
        poll.tick().await;
        match reader.read_line(&mut line).await {
            Ok(0) => {
                line.clear();
            }
            Ok(_) => {
                let trimmed = line.trim_end_matches('\n').trim_end_matches('\r');
                if !trimmed.is_empty() && sink.add(trimmed.to_string()).is_err() {
                    break;
                }
                line.clear();
            }
            Err(e) => return Err(e.into()),
        }
    }

    Ok(())
}
