use crate::api::error::ApiError;
use flutter_rust_bridge::frb;
use nostr_sdk::prelude::*;
use std::time::Duration;

const ZAPSTORE_RELAY: &str = "wss://relay.zapstore.dev";
const ZAPSTORE_APP_PUBKEY: &str =
    "75d737c3472471029c44876b330d2284288a42779b591a2ed4daa1c6c07efaf7";
const ZAPSTORE_APP_IDENTIFIER: &str = "org.parres.whitenoise";
const FETCH_TIMEOUT_SECS: u64 = 10;

// The `a` tag value used to filter kind-30063 release events back to this app.
// Format: "<app-kind>:<pubkey>:<identifier>"
const ZAPSTORE_APP_A_TAG: &str =
    "32267:75d737c3472471029c44876b330d2284288a42779b591a2ed4daa1c6c07efaf7:org.parres.whitenoise";

/// Fetches the latest version string published on Zapstore for White Noise.
///
/// Queries `relay.zapstore.dev` for kind-30063 release artifact set events tagged
/// with this app's `a` tag. The `d` tag on those events contains the version in the
/// format `<identifier>@<version>` (e.g. `org.parres.whitenoise@2026.3.5`).
/// The most recently created event wins.
///
/// Returns `None` when no release has been published yet or the relay is unreachable.
#[frb]
pub async fn fetch_latest_zapstore_version() -> Result<Option<String>, ApiError> {
    let pubkey = PublicKey::from_hex(ZAPSTORE_APP_PUBKEY).map_err(ApiError::from)?;

    // Filter: kind 30063 (release artifact sets) authored by the app publisher,
    // with an `a` tag referencing this app's kind-32267 event.
    let filter = Filter::new()
        .kind(Kind::Custom(30063))
        .author(pubkey)
        .custom_tag(SingleLetterTag::lowercase(Alphabet::A), ZAPSTORE_APP_A_TAG)
        .limit(10); // fetch a few so we can pick the latest by created_at

    let client = Client::default();
    client
        .add_relay(ZAPSTORE_RELAY)
        .await
        .map_err(|e| ApiError::Other {
            message: e.to_string(),
        })?;
    client.connect().await;

    let events = client
        .fetch_events(filter, Duration::from_secs(FETCH_TIMEOUT_SECS))
        .await
        .map_err(|e| ApiError::Other {
            message: e.to_string(),
        })?;

    client.disconnect().await;

    // nostr-sdk returns events sorted newest-first; take the first one.
    let event = match events.first() {
        Some(e) => e,
        None => return Ok(None),
    };

    // The `d` tag value is "<identifier>@<version>", e.g. "org.parres.whitenoise@2026.3.5".
    let version = event.tags.iter().find_map(|tag| {
        let vec = tag.as_slice();
        if vec.first().map(|s| s.as_str()) == Some("d") {
            vec.get(1).and_then(|d_val| {
                d_val
                    .split_once('@')
                    .filter(|(identifier, _)| *identifier == ZAPSTORE_APP_IDENTIFIER)
                    .map(|(_, version)| version.to_string())
            })
        } else {
            None
        }
    });

    Ok(version)
}

#[cfg(test)]
mod tests {
    use super::ZAPSTORE_APP_IDENTIFIER;

    #[test]
    fn test_version_parsed_from_d_tag() {
        let d_val = "org.parres.whitenoise@2026.3.5";
        let version = d_val
            .split_once('@')
            .filter(|(id, _)| *id == ZAPSTORE_APP_IDENTIFIER)
            .map(|(_, v)| v.to_string());
        assert_eq!(version, Some("2026.3.5".to_string()));
    }

    #[test]
    fn test_version_parsing_wrong_identifier_rejected() {
        let d_val = "org.someone.else@2026.3.5";
        let version = d_val
            .split_once('@')
            .filter(|(id, _)| *id == ZAPSTORE_APP_IDENTIFIER)
            .map(|(_, v)| v.to_string());
        assert_eq!(version, None);
    }

    #[test]
    fn test_version_parsing_no_at_sign() {
        let d_val = "org.parres.whitenoise";
        let version = d_val
            .split_once('@')
            .filter(|(id, _)| *id == ZAPSTORE_APP_IDENTIFIER)
            .map(|(_, v)| v.to_string());
        assert_eq!(version, None);
    }
}
