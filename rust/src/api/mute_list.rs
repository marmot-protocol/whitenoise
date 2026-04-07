use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use nostr_sdk::PublicKey;
use whitenoise::{MuteListEntry as WhitenoiseEntry, Whitenoise};

use crate::api::ApiError;

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct MuteListEntry {
    pub account_pubkey: String,
    pub muted_pubkey: String,
    pub is_private: bool,
    pub created_at: DateTime<Utc>,
}

impl From<WhitenoiseEntry> for MuteListEntry {
    fn from(e: WhitenoiseEntry) -> Self {
        Self {
            account_pubkey: e.account_pubkey.to_hex(),
            muted_pubkey: e.muted_pubkey.to_hex(),
            is_private: e.is_private,
            created_at: e.created_at,
        }
    }
}

#[frb]
pub async fn block_user(account_pubkey: String, target_pubkey: String) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account_pubkey = PublicKey::parse(&account_pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&account_pubkey).await?;
    let target = PublicKey::parse(&target_pubkey)?;
    whitenoise
        .block_user(&account, &target)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn unblock_user(account_pubkey: String, target_pubkey: String) -> Result<(), ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account_pubkey = PublicKey::parse(&account_pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&account_pubkey).await?;
    let target = PublicKey::parse(&target_pubkey)?;
    whitenoise
        .unblock_user(&account, &target)
        .await
        .map_err(ApiError::from)
}

#[frb]
pub async fn get_blocked_users(account_pubkey: String) -> Result<Vec<MuteListEntry>, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account_pubkey = PublicKey::parse(&account_pubkey)?;
    let account = whitenoise.find_account_by_pubkey(&account_pubkey).await?;
    let entries = whitenoise.get_blocked_users(&account).await?;
    Ok(entries.into_iter().map(|e| e.into()).collect())
}

#[frb]
pub async fn is_user_blocked(
    account_pubkey: String,
    target_pubkey: String,
) -> Result<bool, ApiError> {
    let whitenoise = Whitenoise::get_instance()?;
    let account_pubkey = PublicKey::parse(&account_pubkey)?;
    let target = PublicKey::parse(&target_pubkey)?;
    whitenoise
        .is_user_blocked(&account_pubkey, &target)
        .await
        .map_err(ApiError::from)
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;
    use nostr_sdk::Keys;
    use whitenoise::MuteListEntry as WhitenoiseEntry;

    #[test]
    fn test_mute_list_entry_conversion() {
        let account_keys = Keys::generate();
        let muted_keys = Keys::generate();
        let now = Utc::now();

        let entry = WhitenoiseEntry {
            account_pubkey: account_keys.public_key(),
            muted_pubkey: muted_keys.public_key(),
            is_private: true,
            created_at: now,
        };

        let flutter_entry: MuteListEntry = entry.into();

        assert_eq!(
            flutter_entry.account_pubkey,
            account_keys.public_key().to_hex()
        );
        assert_eq!(flutter_entry.muted_pubkey, muted_keys.public_key().to_hex());
        assert!(flutter_entry.is_private);
        assert_eq!(flutter_entry.created_at, now);
    }

    #[test]
    fn test_mute_list_entry_conversion_public() {
        let account_keys = Keys::generate();
        let muted_keys = Keys::generate();

        let entry = WhitenoiseEntry {
            account_pubkey: account_keys.public_key(),
            muted_pubkey: muted_keys.public_key(),
            is_private: false,
            created_at: Utc::now(),
        };

        let flutter_entry: MuteListEntry = entry.into();
        assert!(!flutter_entry.is_private);
    }
}
