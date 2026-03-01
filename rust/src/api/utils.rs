//! Utility functions and data structures for White Noise API.
//!
//! This module provides essential utility functions for the White Noise Flutter application,
//! including key management, relay operations, and data conversions.

use crate::api::error::ApiError;
use crate::api::{Language, ThemeMode};
use flutter_rust_bridge::frb;
use mdk_core::prelude::GroupId;
use nostr_sdk::prelude::*;
pub use whitenoise::Whitenoise;

#[frb(sync)]
pub fn npub_from_hex_pubkey(hex_pubkey: &str) -> Result<String, ApiError> {
    Whitenoise::npub_from_hex_pubkey(hex_pubkey).map_err(ApiError::from)
}

#[frb(sync)]
pub fn hex_pubkey_from_npub(npub: &str) -> Result<String, ApiError> {
    let pubkey = PublicKey::parse(npub).map_err(ApiError::from)?;
    Ok(pubkey.to_hex())
}

#[frb]
pub fn relay_url_from_string(url: String) -> Result<RelayUrl, ApiError> {
    RelayUrl::parse(&url).map_err(ApiError::from)
}

#[frb]
pub fn string_from_relay_url(relay_url: &RelayUrl) -> String {
    relay_url.to_string()
}

#[frb]
pub fn tag_from_vec(vec: Vec<String>) -> Result<Tag, ApiError> {
    Ok(Tag::parse(&vec)?)
}

#[frb]
pub fn get_default_blossom_server_url() -> String {
    #[cfg(debug_assertions)]
    {
        "http://localhost:3000".to_string()
    }
    #[cfg(not(debug_assertions))]
    {
        "https://blossom.primal.net".to_string()
    }
}

#[frb]
pub async fn debug_query(sql: String) -> Result<String, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    whitenoise.debug_query(&sql).await.map_err(ApiError::from)
}

#[frb]
pub fn group_id_to_string(group_id: &GroupId) -> String {
    ::hex::encode(group_id.as_slice())
}

#[frb]
pub fn group_id_from_string(group_id: &str) -> Result<GroupId, ApiError> {
    let bytes = ::hex::decode(group_id)?;
    Ok(GroupId::from_slice(&bytes))
}

#[frb(sync)]
pub fn theme_mode_light() -> ThemeMode {
    ThemeMode::Light
}

#[frb(sync)]
pub fn theme_mode_dark() -> ThemeMode {
    ThemeMode::Dark
}

#[frb(sync)]
pub fn theme_mode_system() -> ThemeMode {
    ThemeMode::System
}

#[frb(sync)]
pub fn theme_mode_to_string(theme_mode: &ThemeMode) -> String {
    match theme_mode {
        ThemeMode::Light => "light".to_string(),
        ThemeMode::Dark => "dark".to_string(),
        ThemeMode::System => "system".to_string(),
    }
}

#[frb(sync)]
pub fn language_english() -> Language {
    Language::English
}

#[frb(sync)]
pub fn language_spanish() -> Language {
    Language::Spanish
}

#[frb(sync)]
pub fn language_french() -> Language {
    Language::French
}

#[frb(sync)]
pub fn language_german() -> Language {
    Language::German
}

#[frb(sync)]
pub fn language_italian() -> Language {
    Language::Italian
}

#[frb(sync)]
pub fn language_portuguese() -> Language {
    Language::Portuguese
}

#[frb(sync)]
pub fn language_russian() -> Language {
    Language::Russian
}

#[frb(sync)]
pub fn language_turkish() -> Language {
    Language::Turkish
}

#[frb(sync)]
pub fn language_system() -> Language {
    Language::System
}

#[frb(sync)]
pub fn language_to_string(language: &Language) -> String {
    match language {
        Language::System => "system".to_string(),
        Language::English => "en".to_string(),
        Language::Spanish => "es".to_string(),
        Language::French => "fr".to_string(),
        Language::German => "de".to_string(),
        Language::Italian => "it".to_string(),
        Language::Portuguese => "pt".to_string(),
        Language::Russian => "ru".to_string(),
        Language::Turkish => "tr".to_string(),
    }
}
