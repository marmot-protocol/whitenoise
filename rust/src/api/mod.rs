// Re-export everything from the whitenoise crate
use flutter_rust_bridge::frb;
use std::path::Path;
pub use whitenoise::{AppSettings, Language, RelayType, ThemeMode, Whitenoise};

// Re-export types that flutter_rust_bridge needs
pub use mdk_core::prelude::GroupId;
pub use nostr_sdk::{Event, PublicKey, RelayUrl, Tag};

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
pub mod chat_list;
pub mod drafts;
pub mod error;
pub mod groups;
pub mod logs;
pub mod media_files;
pub mod messages;
pub mod metadata;
pub mod notifications;
pub mod relays;
pub mod signer;
pub mod user_search;
pub mod users;
pub mod utils;

// Re-export everything
pub use account_groups::*;
pub use accounts::*;
pub use chat_list::*;
pub use drafts::*;
pub use error::*;
pub use groups::*;
pub use logs::*;
pub use media_files::*;
pub use messages::*;
pub use metadata::*;
pub use notifications::*;
pub use relays::*;
pub use signer::*;
pub use user_search::*;
pub use users::*;
pub use utils::*;

#[frb]
pub async fn initialize_whitenoise(config: WhitenoiseConfig) -> Result<(), ApiError> {
    let core_config = whitenoise::WhitenoiseConfig::new(
        Path::new(&config.data_dir),
        Path::new(&config.logs_dir),
        "com.whitenoise.app",
    );
    Whitenoise::initialize_whitenoise(core_config)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn delete_all_data() -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.delete_all_data().await.map_err(ApiError::from)
}

#[frb]
pub async fn get_app_settings() -> Result<AppSettings, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.app_settings().await.map_err(ApiError::from)
}

#[frb]
pub async fn update_theme_mode(theme_mode: ThemeMode) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
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
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise
        .update_language(language)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub fn app_settings_language(app_settings: &AppSettings) -> Language {
    app_settings.language.clone()
}
