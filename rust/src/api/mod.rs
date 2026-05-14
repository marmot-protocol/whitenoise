// Re-export everything from the whitenoise crate
use flutter_rust_bridge::frb;
use std::ops::Deref;
use std::path::Path;
use std::sync::{Arc, LazyLock, RwLock as StdRwLock};
use tokio::sync::{Mutex, OwnedRwLockReadGuard, RwLock as TokioRwLock};
pub use whitenoise::{AppSettings, Language, RelayType, ThemeMode, Whitenoise};

static GLOBAL_WN: StdRwLock<Option<Arc<Whitenoise>>> = StdRwLock::new(None);
static GLOBAL_WN_INIT_LOCK: Mutex<()> = Mutex::const_new(());
static WN_LIFECYCLE_LOCK: LazyLock<Arc<TokioRwLock<()>>> =
    LazyLock::new(|| Arc::new(TokioRwLock::new(())));

pub(crate) struct WnHandle {
    whitenoise: Arc<Whitenoise>,
    _lifecycle_permit: OwnedRwLockReadGuard<()>,
}

impl WnHandle {
    /// Consumes the handle to drop its lifecycle read permit before entering a
    /// long-lived stream receive loop. The subscription receiver is already
    /// detached from this handle by then, so delete/reset can proceed instead
    /// of waiting on an open UI stream forever.
    pub(crate) fn release_lifecycle(self) {}
}

impl Deref for WnHandle {
    type Target = Whitenoise;

    fn deref(&self) -> &Self::Target {
        self.whitenoise.as_ref()
    }
}

pub(crate) struct WnSessionHandle {
    session: Arc<whitenoise::whitenoise::session::AccountSession>,
    // Keeps delete_all_data from closing the shared database while a session
    // bridge call is using the session. Long-lived session streams should add
    // an explicit release method before waiting on their receive loop.
    _wn: WnHandle,
}

impl Deref for WnSessionHandle {
    type Target = whitenoise::whitenoise::session::AccountSession;

    fn deref(&self) -> &Self::Target {
        self.session.as_ref()
    }
}

pub(crate) async fn wn() -> Result<WnHandle, error::ApiError> {
    let lifecycle_permit = Arc::clone(&WN_LIFECYCLE_LOCK).read_owned().await;
    let whitenoise = GLOBAL_WN
        .read()
        .map_err(|_| error::ApiError::Whitenoise {
            message: "Whitenoise global state lock poisoned".to_string(),
        })?
        .as_ref()
        .map(Arc::clone)
        .ok_or_else(|| error::ApiError::Whitenoise {
            message: "Whitenoise not initialized".to_string(),
        })?;
    Ok(WnHandle {
        whitenoise,
        _lifecycle_permit: lifecycle_permit,
    })
}

pub(crate) async fn wn_session(
    pubkey: &nostr_sdk::PublicKey,
) -> Result<WnSessionHandle, error::ApiError> {
    let wn = wn().await?;
    let session = wn
        .session(pubkey)
        .ok_or_else(|| error::ApiError::Whitenoise {
            message: "Account session not found".to_string(),
        })?;
    Ok(WnSessionHandle { session, _wn: wn })
}

// Re-export types that flutter_rust_bridge needs
pub use nostr_sdk::{Event, PublicKey, RelayUrl, Tag};
pub use whitenoise::mdk::GroupId;

/// Flutter-compatible configuration structure that holds directory paths as strings.
///
/// This struct is used to pass configuration data from Flutter to Rust, as flutter_rust_bridge
/// cannot directly handle `Path` types. The paths are converted to proper `Path` objects
/// internally when creating a `WhitenoiseConfig`.
#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct WhitenoiseConfig {
    /// Path to the directory where application data will be stored
    pub data_dir: String,
    /// Path to the directory where log files will be written
    pub logs_dir: String,
}

impl From<whitenoise::WhitenoiseConfig> for WhitenoiseConfig {
    fn from(config: whitenoise::WhitenoiseConfig) -> Self {
        Self {
            data_dir: config.data_dir.to_string_lossy().to_string(),
            logs_dir: config.logs_dir.to_string_lossy().to_string(),
        }
    }
}

fn to_core_config(config: &WhitenoiseConfig) -> whitenoise::WhitenoiseConfig {
    whitenoise::WhitenoiseConfig::new(
        Path::new(&config.data_dir),
        Path::new(&config.logs_dir),
        "com.whitenoise.app",
    )
}

/// Creates a `WhitenoiseConfig` object from string directory paths.
///
/// This function bridges the gap between Flutter's string-based paths and Rust's
/// `Path` types, creating a proper configuration object for Whitenoise initialization.
///
/// # Parameters
/// * `data_dir` - Path string for data directory where app data will be stored
/// * `logs_dir` - Path string for logs directory where log files will be written
///
/// # Returns
/// A WhitenoiseConfig object ready for initialization
///
/// # Example
/// ```rust
/// let config = create_whitenoise_config(
///     "/path/to/data".to_string(),
///     "/path/to/logs".to_string()
/// );
/// ```
#[frb]
pub fn create_whitenoise_config(data_dir: String, logs_dir: String) -> WhitenoiseConfig {
    WhitenoiseConfig { data_dir, logs_dir }
}

// Declare the modules
pub mod account_groups;
pub mod accounts;
pub mod bug_report;
pub mod chat_list;
pub mod chat_summary;
pub mod drafts;
pub mod error;
pub mod group_state;
pub mod groups;
pub mod logs;
pub mod media_files;
pub mod messages;
pub mod metadata;
pub mod mute_list;
pub mod notifications;
pub mod relay_defaults;
pub mod relays;
pub mod signer;
pub mod user_search;
pub mod users;
pub mod utils;
pub mod zapstore;

// Re-export everything
pub use account_groups::*;
pub use accounts::*;
pub use bug_report::*;
pub use chat_list::*;
pub use chat_summary::*;
pub use drafts::*;
pub use error::*;
pub use group_state::*;
pub use groups::*;
pub use logs::*;
pub use media_files::*;
pub use messages::*;
pub use metadata::*;
pub use mute_list::*;
pub use notifications::*;
pub use relay_defaults::*;
pub use relays::*;
pub use signer::*;
pub use user_search::*;
pub use users::*;
pub use utils::*;
pub use zapstore::*;

#[frb]
pub async fn initialize_whitenoise(config: WhitenoiseConfig) -> Result<(), ApiError> {
    if GLOBAL_WN
        .read()
        .map_err(|_| ApiError::Whitenoise {
            message: "Whitenoise global state lock poisoned".to_string(),
        })?
        .is_some()
    {
        return Ok(());
    }

    let _init_guard = GLOBAL_WN_INIT_LOCK.lock().await;
    if GLOBAL_WN
        .read()
        .map_err(|_| ApiError::Whitenoise {
            message: "Whitenoise global state lock poisoned".to_string(),
        })?
        .is_some()
    {
        return Ok(());
    }

    let core_config = to_core_config(&config);
    let whitenoise = Whitenoise::new(core_config.clone())
        .await
        .map_err(ApiError::from)?;
    *GLOBAL_WN.write().map_err(|_| ApiError::Whitenoise {
        message: "Whitenoise global state lock poisoned".to_string(),
    })? = Some(whitenoise);

    Ok(())
}

/// Wipes all on-disk data and installs a fresh Whitenoise instance before
/// returning. The lifecycle write lock waits for in-flight bridge calls before
/// the old database pool is closed, then blocks new bridge calls until the fresh
/// instance is ready.
#[frb]
pub async fn delete_all_data() -> Result<(), ApiError> {
    let _init_guard = GLOBAL_WN_INIT_LOCK.lock().await;
    let _lifecycle_guard = WN_LIFECYCLE_LOCK.write().await;
    let whitenoise = GLOBAL_WN
        .write()
        .map_err(|_| ApiError::Whitenoise {
            message: "Whitenoise global state lock poisoned".to_string(),
        })?
        .take()
        .ok_or_else(|| ApiError::Whitenoise {
            message: "Whitenoise not initialized".to_string(),
        })?;
    let core_config = whitenoise.config().clone();

    whitenoise.delete_all_data().await.map_err(ApiError::from)?;
    drop(whitenoise);

    let whitenoise = Whitenoise::new(core_config).await.map_err(ApiError::from)?;
    *GLOBAL_WN.write().map_err(|_| ApiError::Whitenoise {
        message: "Whitenoise global state lock poisoned".to_string(),
    })? = Some(whitenoise);

    Ok(())
}

#[frb]
pub async fn get_app_settings() -> Result<AppSettings, ApiError> {
    let whitenoise = wn().await?;
    whitenoise.app_settings().await.map_err(ApiError::from)
}

#[frb]
pub async fn update_theme_mode(theme_mode: ThemeMode) -> Result<(), ApiError> {
    let whitenoise = wn().await?;
    whitenoise
        .update_theme_mode(theme_mode)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub fn app_settings_theme_mode(app_settings: &AppSettings) -> ThemeMode {
    app_settings.theme_mode.clone()
}

#[frb]
pub async fn update_language(language: Language) -> Result<(), ApiError> {
    let whitenoise = wn().await?;
    whitenoise
        .update_language(language)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub fn app_settings_language(app_settings: &AppSettings) -> Language {
    app_settings.language.clone()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;
    use tokio::sync::oneshot;

    #[tokio::test(flavor = "current_thread")]
    async fn lifecycle_write_waits_for_read_permit_to_drop() {
        let read_guard = Arc::clone(&WN_LIFECYCLE_LOCK).read_owned().await;
        let (acquired_tx, acquired_rx) = oneshot::channel();

        let writer = tokio::spawn(async move {
            let _write_guard = WN_LIFECYCLE_LOCK.write().await;
            let _ = acquired_tx.send(());
        });

        tokio::select! {
            _ = acquired_rx => panic!("writer acquired lifecycle lock before read permit dropped"),
            _ = tokio::task::yield_now() => {}
        }

        drop(read_guard);
        writer.await.expect("writer task should complete");
    }

    #[test]
    fn stream_receive_loops_release_lifecycle_before_waiting() {
        let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let api_dir = manifest_dir.join("src/api");
        let stream_files = [
            "chat_list.rs",
            "group_state.rs",
            "messages.rs",
            "notifications.rs",
            "user_search.rs",
            "users.rs",
        ];

        for file_name in stream_files {
            let source = std::fs::read_to_string(api_dir.join(file_name))
                .unwrap_or_else(|e| panic!("failed to read {file_name}: {e}"));
            for (offset, segment) in source.split("rx.recv().await").enumerate().skip(1) {
                let before = source
                    .split("rx.recv().await")
                    .take(offset)
                    .collect::<Vec<_>>()
                    .join("rx.recv().await");
                let after_last_receiver = before.rsplit("let mut rx =").next().unwrap_or(&before);
                assert!(
                    after_last_receiver.contains("release_lifecycle()"),
                    "{file_name} has an rx.recv().await loop without release_lifecycle() after \
                     its receiver setup; nearby suffix: {:?}",
                    &segment[..segment.len().min(120)]
                );
            }
        }
    }
}
