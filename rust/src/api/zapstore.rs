use crate::api::error::ApiError;
use flutter_rust_bridge::frb;
use nostr_sdk::prelude::*;
use std::time::Duration;

const ZAPSTORE_RELAY: &str = "wss://relay.zapstore.dev";
const ZAPSTORE_APP_PUBKEY: &str =
    "75d737c3472471029c44876b330d2284288a42779b591a2ed4daa1c6c07efaf7";
const ZAPSTORE_APP_IDENTIFIER: &str = "org.parres.whitenoise";
const FETCH_TIMEOUT_SECS: u64 = 10;

/// Fetches the latest version string published on Zapstore for White Noise.
///
/// Queries the Zapstore relay for the kind-32267 software application event,
/// then extracts the version from the `a` tag pointing at the latest kind-30063
/// release artifact set (format: `30063:<pubkey>:<identifier>@<version>`).
///
/// Returns `None` when no release has been published yet or the relay is unreachable.
#[frb]
pub async fn fetch_latest_zapstore_version() -> Result<Option<String>, ApiError> {
    let pubkey = PublicKey::from_hex(ZAPSTORE_APP_PUBKEY).map_err(ApiError::from)?;

    let filter = Filter::new()
        .kind(Kind::Custom(32267))
        .author(pubkey)
        .identifier(ZAPSTORE_APP_IDENTIFIER)
        .limit(1);

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

    let event = match events.first() {
        Some(e) => e,
        None => return Ok(None),
    };

    // The `a` tag points at the latest release: "30063:<pubkey>:<identifier>@<version>"
    let version = event
        .tags
        .iter()
        .filter_map(|tag| {
            let vec = tag.as_slice();
            if vec.first().map(|s| s.as_str()) == Some("a") {
                vec.get(1).map(|s| s.as_str())
            } else {
                None
            }
        })
        .find_map(|coord| {
            // Format: "30063:<pubkey>:<identifier>@<version>"
            let parts: Vec<&str> = coord.splitn(3, ':').collect();
            if parts.first() == Some(&"30063") {
                parts.get(2).and_then(|id_at_ver| {
                    id_at_ver
                        .split_once('@')
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

    #[test]
    fn test_version_parsed_from_a_tag() {
        // Simulate the a-tag value format used by Zapstore
        let coord = "30063:75d737c3472471029c44876b330d2284288a42779b591a2ed4daa1c6c07efaf7:org.parres.whitenoise@2026.3.5";
        let parts: Vec<&str> = coord.splitn(3, ':').collect();
        assert_eq!(parts[0], "30063");
        let version = parts
            .get(2)
            .and_then(|id_at_ver| id_at_ver.split_once('@').map(|(_, v)| v.to_string()));
        assert_eq!(version, Some("2026.3.5".to_string()));
    }

    #[test]
    fn test_version_parsing_no_at_sign() {
        let coord = "30063:75d737c3472471029c44876b330d2284288a42779b591a2ed4daa1c6c07efaf7:org.parres.whitenoise";
        let parts: Vec<&str> = coord.splitn(3, ':').collect();
        let version = parts
            .get(2)
            .and_then(|id_at_ver| id_at_ver.split_once('@').map(|(_, v)| v.to_string()));
        assert_eq!(version, None);
    }

    #[test]
    fn test_version_parsing_wrong_kind() {
        let coord = "32267:75d737c3472471029c44876b330d2284288a42779b591a2ed4daa1c6c07efaf7:org.parres.whitenoise@2026.3.5";
        let parts: Vec<&str> = coord.splitn(3, ':').collect();
        let version = if parts.first() == Some(&"30063") {
            parts
                .get(2)
                .and_then(|id_at_ver| id_at_ver.split_once('@').map(|(_, v)| v.to_string()))
        } else {
            None
        };
        assert_eq!(version, None);
    }
}
