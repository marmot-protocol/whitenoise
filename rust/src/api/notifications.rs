use crate::api::error::ApiError;
use crate::api::utils::{group_id_from_string, group_id_to_string};
use crate::api::{wn, wn_session};
use crate::frb_generated::StreamSink;
use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use nostr_sdk::{PublicKey, RelayUrl};
use whitenoise::whitenoise::notification_streaming::{
    NotificationTrigger as WhitenoiseNotificationTrigger,
    NotificationUpdate as WhitenoiseNotificationUpdate,
    NotificationUser as WhitenoiseNotificationUser,
};
use whitenoise::whitenoise::push_notifications::{
    GroupPushDebugInfo as WhitenoiseGroupPushDebugInfo,
    GroupPushTokenDebugEntry as WhitenoiseGroupPushTokenDebugEntry,
    LocalPushRegistrationDebugInfo as WhitenoiseLocalPushRegistrationDebugInfo,
    PushPlatform as WhitenoisePushPlatform, PushRegistration as WhitenoisePushRegistration,
};

#[frb]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum NotificationTrigger {
    NewMessage,
    GroupInvite,
}

impl From<WhitenoiseNotificationTrigger> for NotificationTrigger {
    fn from(trigger: WhitenoiseNotificationTrigger) -> Self {
        match trigger {
            WhitenoiseNotificationTrigger::NewMessage => Self::NewMessage,
            WhitenoiseNotificationTrigger::GroupInvite => Self::GroupInvite,
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct NotificationUser {
    pub pubkey: String,
    pub display_name: Option<String>,
    pub picture_url: Option<String>,
}

impl From<WhitenoiseNotificationUser> for NotificationUser {
    fn from(user: WhitenoiseNotificationUser) -> Self {
        Self {
            pubkey: user.pubkey.to_hex(),
            display_name: user.display_name,
            picture_url: user.picture_url,
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct NotificationUpdate {
    pub trigger: NotificationTrigger,
    pub mls_group_id: String,
    pub group_name: Option<String>,
    pub is_dm: bool,
    pub receiver: NotificationUser,
    pub sender: NotificationUser,
    pub content: String,
    pub timestamp: DateTime<Utc>,
}

impl From<WhitenoiseNotificationUpdate> for NotificationUpdate {
    fn from(update: WhitenoiseNotificationUpdate) -> Self {
        Self {
            trigger: update.trigger.into(),
            mls_group_id: group_id_to_string(&update.mls_group_id),
            group_name: update.group_name,
            is_dm: update.is_dm,
            receiver: update.receiver.into(),
            sender: update.sender.into(),
            content: update.content,
            timestamp: update.timestamp,
        }
    }
}

#[frb]
pub async fn subscribe_to_notifications(
    sink: StreamSink<NotificationUpdate>,
) -> Result<(), ApiError> {
    let whitenoise = wn().await?;
    let subscription = whitenoise.subscribe_to_notifications();
    let mut rx = subscription.updates;
    whitenoise.release_lifecycle();

    loop {
        match rx.recv().await {
            Ok(update) => {
                let item: NotificationUpdate = update.into();
                if sink.add(item).is_err() {
                    break; // Sink closed
                }
            }
            Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => {
                continue;
            }
            Err(tokio::sync::broadcast::error::RecvError::Closed) => {
                break;
            }
        }
    }

    Ok(())
}

#[frb]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PushPlatform {
    Apns,
    Fcm,
}

impl From<PushPlatform> for WhitenoisePushPlatform {
    fn from(p: PushPlatform) -> Self {
        match p {
            PushPlatform::Apns => Self::Apns,
            PushPlatform::Fcm => Self::Fcm,
        }
    }
}

impl From<WhitenoisePushPlatform> for PushPlatform {
    fn from(p: WhitenoisePushPlatform) -> Self {
        match p {
            WhitenoisePushPlatform::Apns => Self::Apns,
            WhitenoisePushPlatform::Fcm => Self::Fcm,
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct PushRegistration {
    pub account_pubkey: String,
    pub platform: PushPlatform,
    pub raw_token: String,
    pub server_pubkey: String,
    pub relay_hint: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub last_shared_at: Option<DateTime<Utc>>,
}

impl From<WhitenoisePushRegistration> for PushRegistration {
    fn from(r: WhitenoisePushRegistration) -> Self {
        Self {
            account_pubkey: r.account_pubkey.to_hex(),
            platform: r.platform.into(),
            raw_token: r.raw_token,
            server_pubkey: r.server_pubkey.to_hex(),
            relay_hint: r.relay_hint.map(|u| u.to_string()),
            created_at: r.created_at,
            updated_at: r.updated_at,
            last_shared_at: r.last_shared_at,
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct LocalPushRegistrationDebugInfo {
    pub registered: bool,
    pub shareable: bool,
    pub notifications_enabled: bool,
    pub local_leaf_index: Option<u32>,
    pub local_token_cached: bool,
}

impl From<WhitenoiseLocalPushRegistrationDebugInfo> for LocalPushRegistrationDebugInfo {
    fn from(info: WhitenoiseLocalPushRegistrationDebugInfo) -> Self {
        Self {
            registered: info.registered,
            shareable: info.shareable,
            notifications_enabled: info.notifications_enabled,
            local_leaf_index: info.local_leaf_index,
            local_token_cached: info.local_token_cached,
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct GroupPushTokenDebugEntry {
    pub member_pubkey: String,
    pub leaf_index: u32,
    pub server_pubkey: String,
    pub has_relay_hint: bool,
    pub active_leaf: bool,
    pub member_matches_active_leaf: bool,
    pub is_local_member: bool,
    pub updated_at: DateTime<Utc>,
}

impl From<WhitenoiseGroupPushTokenDebugEntry> for GroupPushTokenDebugEntry {
    fn from(entry: WhitenoiseGroupPushTokenDebugEntry) -> Self {
        Self {
            member_pubkey: entry.member_pubkey.to_hex(),
            leaf_index: entry.leaf_index,
            server_pubkey: entry.server_pubkey.to_hex(),
            has_relay_hint: entry.has_relay_hint,
            active_leaf: entry.active_leaf,
            member_matches_active_leaf: entry.member_matches_active_leaf,
            is_local_member: entry.is_local_member,
            updated_at: entry.updated_at,
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone)]
pub struct GroupPushDebugInfo {
    pub total_token_count: u32,
    pub active_token_count: u32,
    pub stale_token_count: u32,
    pub missing_relay_hint_count: u32,
    pub last_token_list_updated_at: Option<DateTime<Utc>>,
    pub local_registration: LocalPushRegistrationDebugInfo,
    pub tokens: Vec<GroupPushTokenDebugEntry>,
}

impl From<WhitenoiseGroupPushDebugInfo> for GroupPushDebugInfo {
    fn from(info: WhitenoiseGroupPushDebugInfo) -> Self {
        Self {
            total_token_count: info.total_token_count as u32,
            active_token_count: info.active_token_count as u32,
            stale_token_count: info.stale_token_count as u32,
            missing_relay_hint_count: info.missing_relay_hint_count as u32,
            last_token_list_updated_at: info.last_token_list_updated_at,
            local_registration: info.local_registration.into(),
            tokens: info
                .tokens
                .into_iter()
                .map(GroupPushTokenDebugEntry::from)
                .collect(),
        }
    }
}

#[frb]
// Reserved for settings/sign-out flows that need to inspect or clear the local push registration.
pub async fn get_push_registration(pubkey: String) -> Result<Option<PushRegistration>, ApiError> {
    let pubkey = PublicKey::parse(&pubkey)?;
    let session = wn_session(&pubkey).await?;
    let registration = session.push().registration().await?;
    Ok(registration.map(PushRegistration::from))
}

#[frb]
pub async fn get_group_push_debug_info(
    pubkey: String,
    group_id: String,
) -> Result<GroupPushDebugInfo, ApiError> {
    let pubkey = PublicKey::parse(&pubkey)?;
    let group_id = group_id_from_string(&group_id)?;
    let session = wn_session(&pubkey).await?;
    let info = session.push().get_group_debug_info(&group_id).await?;
    Ok(info.into())
}

#[frb]
pub async fn upsert_push_registration(
    pubkey: String,
    platform: PushPlatform,
    raw_token: String,
    server_pubkey: String,
    relay_hint: Option<String>,
) -> Result<PushRegistration, ApiError> {
    let pubkey = PublicKey::parse(&pubkey)?;
    let server_pk = PublicKey::parse(&server_pubkey)?;
    let relay = relay_hint
        .as_deref()
        .map(RelayUrl::parse)
        .transpose()
        .map_err(ApiError::from)?;
    let session = wn_session(&pubkey).await?;
    let registration = session
        .push()
        .upsert_registration(platform.into(), &raw_token, &server_pk, relay.as_ref())
        .await?;
    Ok(registration.into())
}

#[frb]
// Reserved for settings/sign-out flows that need to inspect or clear the local push registration.
pub async fn clear_push_registration(pubkey: String) -> Result<(), ApiError> {
    let pubkey = PublicKey::parse(&pubkey)?;
    let session = wn_session(&pubkey).await?;
    session.push().clear_registration().await?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_notification_trigger_conversion_new_message() {
        let trigger: NotificationTrigger = WhitenoiseNotificationTrigger::NewMessage.into();
        assert_eq!(trigger, NotificationTrigger::NewMessage);
    }

    #[test]
    fn test_notification_trigger_conversion_group_invite() {
        let trigger: NotificationTrigger = WhitenoiseNotificationTrigger::GroupInvite.into();
        assert_eq!(trigger, NotificationTrigger::GroupInvite);
    }
}
