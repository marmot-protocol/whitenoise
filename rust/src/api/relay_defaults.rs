use std::sync::OnceLock;

use crate::api::error::ApiError;
use flutter_rust_bridge::frb;
use nostr_sdk::prelude::RelayUrl;

pub const PRODUCTION_RELAY_URLS: [&str; 3] = [
    "wss://nos.lol",
    "wss://relay.primal.net",
    "wss://relay.damus.io",
];
pub const BUG_REPORT_RELAY_URLS: [&str; 3] = PRODUCTION_RELAY_URLS;
pub const DEFAULT_RELAY_URLS: [&str; 3] = PRODUCTION_RELAY_URLS;

static DEFAULT_RELAY_URLS_OVERRIDE: OnceLock<Vec<String>> = OnceLock::new();

pub(crate) fn configure_default_relay_urls(
    relay_urls: Option<Vec<String>>,
) -> Result<(), ApiError> {
    let Some(relay_urls) = relay_urls else {
        return Ok(());
    };
    if relay_urls.is_empty() {
        return Err(ApiError::Other {
            message: "Default relay URL list cannot be empty".to_string(),
        });
    }
    parse_relay_urls(&relay_urls)?;

    match DEFAULT_RELAY_URLS_OVERRIDE.set(relay_urls) {
        Ok(()) => Ok(()),
        Err(relay_urls) => {
            if DEFAULT_RELAY_URLS_OVERRIDE.get() == Some(&relay_urls) {
                Ok(())
            } else {
                Err(ApiError::Other {
                    message: "Default relay URLs are already configured".to_string(),
                })
            }
        }
    }
}

fn configured_default_relay_urls() -> Vec<String> {
    DEFAULT_RELAY_URLS_OVERRIDE
        .get()
        .cloned()
        .unwrap_or_else(|| {
            DEFAULT_RELAY_URLS
                .iter()
                .map(|url| (*url).to_string())
                .collect()
        })
}

fn parse_relay_urls(relay_urls: &[String]) -> Result<Vec<RelayUrl>, ApiError> {
    relay_urls
        .iter()
        .map(|url| RelayUrl::parse(url))
        .collect::<Result<Vec<_>, _>>()
        .map_err(ApiError::from)
}

#[frb]
pub fn default_relay_urls_parsed() -> Result<Vec<RelayUrl>, ApiError> {
    parse_relay_urls(&configured_default_relay_urls())
}

#[frb(sync)]
pub fn default_relay_urls() -> Vec<String> {
    configured_default_relay_urls()
}

#[cfg(test)]
mod tests {
    use super::{
        BUG_REPORT_RELAY_URLS, DEFAULT_RELAY_URLS, PRODUCTION_RELAY_URLS, default_relay_urls,
        default_relay_urls_parsed,
    };

    #[test]
    fn default_relay_urls_parse() {
        let relays = default_relay_urls_parsed()
            .expect("default relay URLs must stay valid")
            .into_iter()
            .map(|relay| relay.to_string())
            .collect::<Vec<_>>();

        assert_eq!(relays, DEFAULT_RELAY_URLS);
    }

    #[test]
    fn default_relay_urls_strings_match_constant() {
        let relay_urls = default_relay_urls();
        let expected = DEFAULT_RELAY_URLS
            .iter()
            .map(|url| (*url).to_string())
            .collect::<Vec<_>>();
        assert_eq!(relay_urls, expected);
    }

    #[test]
    fn bug_report_relays_stay_on_production_relays() {
        assert_eq!(BUG_REPORT_RELAY_URLS, PRODUCTION_RELAY_URLS);
    }

    #[test]
    fn configured_relay_overrides_reject_invalid_urls() {
        let result = super::configure_default_relay_urls(Some(vec!["not a relay".to_string()]));

        assert!(result.is_err());
    }

    #[test]
    fn configured_relay_overrides_reject_empty_lists() {
        let result = super::configure_default_relay_urls(Some(vec![]));

        assert!(result.is_err());
    }
}
