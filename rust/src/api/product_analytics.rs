use crate::api::{error::ApiError, wn};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::frb;
use whitenoise::{
    AptabaseAnalyticsConfig as WhitenoiseAptabaseAnalyticsConfig,
    PRODUCT_ANALYTICS_CONSENT_VERSION,
    ProductAnalyticsBackend as WhitenoiseProductAnalyticsBackend,
    ProductAnalyticsConfig as WhitenoiseProductAnalyticsConfig,
    ProductAnalyticsDeviceClass as WhitenoiseProductAnalyticsDeviceClass,
    ProductAnalyticsEvent as WhitenoiseProductAnalyticsEvent,
    ProductAnalyticsEventName as WhitenoiseProductAnalyticsEventName,
    ProductAnalyticsFlushStatus as WhitenoiseProductAnalyticsFlushStatus,
    ProductAnalyticsNumberProp as WhitenoiseProductAnalyticsNumberProp,
    ProductAnalyticsSettings as WhitenoiseProductAnalyticsSettings,
    ProductAnalyticsStringProp as WhitenoiseProductAnalyticsStringProp,
    ProductAnalyticsTrackStatus as WhitenoiseProductAnalyticsTrackStatus,
};

#[frb(non_opaque)]
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProductAnalyticsSettings {
    pub enabled: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub consent_version: String,
}

impl From<WhitenoiseProductAnalyticsSettings> for ProductAnalyticsSettings {
    fn from(settings: WhitenoiseProductAnalyticsSettings) -> Self {
        Self {
            enabled: settings.enabled,
            created_at: settings.created_at,
            updated_at: settings.updated_at,
            consent_version: settings.consent_version,
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProductAnalyticsConfig {
    pub backend: ProductAnalyticsBackend,
    pub app_version: String,
    pub bundle_identifier: String,
    pub device_class: ProductAnalyticsDeviceClass,
    pub os_name: String,
    pub locale: String,
    pub is_debug: bool,
}

impl From<ProductAnalyticsConfig> for WhitenoiseProductAnalyticsConfig {
    fn from(config: ProductAnalyticsConfig) -> Self {
        Self {
            backend: config.backend.into(),
            app_version: config.app_version,
            bundle_identifier: config.bundle_identifier,
            device_class: config.device_class.into(),
            os_name: config.os_name,
            locale: config.locale,
            is_debug: config.is_debug,
        }
    }
}

impl From<WhitenoiseProductAnalyticsConfig> for ProductAnalyticsConfig {
    fn from(config: WhitenoiseProductAnalyticsConfig) -> Self {
        Self {
            backend: config.backend.into(),
            app_version: config.app_version,
            bundle_identifier: config.bundle_identifier,
            device_class: config.device_class.into(),
            os_name: config.os_name,
            locale: config.locale,
            is_debug: config.is_debug,
        }
    }
}

#[frb]
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ProductAnalyticsBackend {
    Disabled,
    Aptabase { config: AptabaseAnalyticsConfig },
}

impl From<ProductAnalyticsBackend> for WhitenoiseProductAnalyticsBackend {
    fn from(backend: ProductAnalyticsBackend) -> Self {
        match backend {
            ProductAnalyticsBackend::Disabled => Self::Disabled,
            ProductAnalyticsBackend::Aptabase { config } => Self::Aptabase(config.into()),
        }
    }
}

impl From<WhitenoiseProductAnalyticsBackend> for ProductAnalyticsBackend {
    fn from(backend: WhitenoiseProductAnalyticsBackend) -> Self {
        match backend {
            WhitenoiseProductAnalyticsBackend::Disabled => Self::Disabled,
            WhitenoiseProductAnalyticsBackend::Aptabase(config) => Self::Aptabase {
                config: config.into(),
            },
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AptabaseAnalyticsConfig {
    pub app_key: String,
    pub host: String,
}

impl From<AptabaseAnalyticsConfig> for WhitenoiseAptabaseAnalyticsConfig {
    fn from(config: AptabaseAnalyticsConfig) -> Self {
        Self {
            app_key: config.app_key,
            host: config.host,
        }
    }
}

impl From<WhitenoiseAptabaseAnalyticsConfig> for AptabaseAnalyticsConfig {
    fn from(config: WhitenoiseAptabaseAnalyticsConfig) -> Self {
        Self {
            app_key: config.app_key,
            host: config.host,
        }
    }
}

#[frb]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProductAnalyticsDeviceClass {
    Phone,
    Tablet,
    Desktop,
    Unknown,
}

impl From<ProductAnalyticsDeviceClass> for WhitenoiseProductAnalyticsDeviceClass {
    fn from(device_class: ProductAnalyticsDeviceClass) -> Self {
        match device_class {
            ProductAnalyticsDeviceClass::Phone => Self::Phone,
            ProductAnalyticsDeviceClass::Tablet => Self::Tablet,
            ProductAnalyticsDeviceClass::Desktop => Self::Desktop,
            ProductAnalyticsDeviceClass::Unknown => Self::Unknown,
        }
    }
}

impl From<WhitenoiseProductAnalyticsDeviceClass> for ProductAnalyticsDeviceClass {
    fn from(device_class: WhitenoiseProductAnalyticsDeviceClass) -> Self {
        match device_class {
            WhitenoiseProductAnalyticsDeviceClass::Phone => Self::Phone,
            WhitenoiseProductAnalyticsDeviceClass::Tablet => Self::Tablet,
            WhitenoiseProductAnalyticsDeviceClass::Desktop => Self::Desktop,
            WhitenoiseProductAnalyticsDeviceClass::Unknown => Self::Unknown,
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone, PartialEq)]
pub struct ProductAnalyticsEvent {
    pub name: ProductAnalyticsEventName,
    pub string_props: Vec<ProductAnalyticsStringProp>,
    pub number_props: Vec<ProductAnalyticsNumberProp>,
}

impl From<ProductAnalyticsEvent> for WhitenoiseProductAnalyticsEvent {
    fn from(event: ProductAnalyticsEvent) -> Self {
        let mut converted = WhitenoiseProductAnalyticsEvent::new(event.name.into());
        for prop in event.string_props {
            converted.string_props.push(prop.into());
        }
        for prop in event.number_props {
            converted.number_props.push(prop.into());
        }
        converted
    }
}

#[frb]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProductAnalyticsEventName {
    AnalyticsEnabled,
    AppStarted,
    AppForegrounded,
    AppBackgrounded,
    OnboardingStarted,
    OnboardingCompleted,
    IdentityCreated,
    LoginStarted,
    LoginCompleted,
    LoginFailed,
    MessageSendStarted,
    MessageSendCompleted,
    MessageSendFailed,
    GroupCreateStarted,
    GroupCreateCompleted,
    GroupCreateFailed,
    MembersAdded,
    MembersRemoved,
    GroupDataUpdated,
    MediaUploadStarted,
    MediaUploadCompleted,
    MediaUploadFailed,
    PushRegistrationCompleted,
    PushRegistrationFailed,
    SettingChanged,
}

impl From<ProductAnalyticsEventName> for WhitenoiseProductAnalyticsEventName {
    fn from(name: ProductAnalyticsEventName) -> Self {
        match name {
            ProductAnalyticsEventName::AnalyticsEnabled => Self::AnalyticsEnabled,
            ProductAnalyticsEventName::AppStarted => Self::AppStarted,
            ProductAnalyticsEventName::AppForegrounded => Self::AppForegrounded,
            ProductAnalyticsEventName::AppBackgrounded => Self::AppBackgrounded,
            ProductAnalyticsEventName::OnboardingStarted => Self::OnboardingStarted,
            ProductAnalyticsEventName::OnboardingCompleted => Self::OnboardingCompleted,
            ProductAnalyticsEventName::IdentityCreated => Self::IdentityCreated,
            ProductAnalyticsEventName::LoginStarted => Self::LoginStarted,
            ProductAnalyticsEventName::LoginCompleted => Self::LoginCompleted,
            ProductAnalyticsEventName::LoginFailed => Self::LoginFailed,
            ProductAnalyticsEventName::MessageSendStarted => Self::MessageSendStarted,
            ProductAnalyticsEventName::MessageSendCompleted => Self::MessageSendCompleted,
            ProductAnalyticsEventName::MessageSendFailed => Self::MessageSendFailed,
            ProductAnalyticsEventName::GroupCreateStarted => Self::GroupCreateStarted,
            ProductAnalyticsEventName::GroupCreateCompleted => Self::GroupCreateCompleted,
            ProductAnalyticsEventName::GroupCreateFailed => Self::GroupCreateFailed,
            ProductAnalyticsEventName::MembersAdded => Self::MembersAdded,
            ProductAnalyticsEventName::MembersRemoved => Self::MembersRemoved,
            ProductAnalyticsEventName::GroupDataUpdated => Self::GroupDataUpdated,
            ProductAnalyticsEventName::MediaUploadStarted => Self::MediaUploadStarted,
            ProductAnalyticsEventName::MediaUploadCompleted => Self::MediaUploadCompleted,
            ProductAnalyticsEventName::MediaUploadFailed => Self::MediaUploadFailed,
            ProductAnalyticsEventName::PushRegistrationCompleted => Self::PushRegistrationCompleted,
            ProductAnalyticsEventName::PushRegistrationFailed => Self::PushRegistrationFailed,
            ProductAnalyticsEventName::SettingChanged => Self::SettingChanged,
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProductAnalyticsStringProp {
    pub key: String,
    pub value: String,
}

impl From<ProductAnalyticsStringProp> for WhitenoiseProductAnalyticsStringProp {
    fn from(prop: ProductAnalyticsStringProp) -> Self {
        Self {
            key: prop.key,
            value: prop.value,
        }
    }
}

#[frb(non_opaque)]
#[derive(Debug, Clone, PartialEq)]
pub struct ProductAnalyticsNumberProp {
    pub key: String,
    pub value: f64,
}

impl From<ProductAnalyticsNumberProp> for WhitenoiseProductAnalyticsNumberProp {
    fn from(prop: ProductAnalyticsNumberProp) -> Self {
        Self {
            key: prop.key,
            value: prop.value,
        }
    }
}

#[frb]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProductAnalyticsTrackStatus {
    Queued,
    IgnoredDisabled,
    IgnoredUnconfigured,
}

impl From<WhitenoiseProductAnalyticsTrackStatus> for ProductAnalyticsTrackStatus {
    fn from(status: WhitenoiseProductAnalyticsTrackStatus) -> Self {
        match status {
            WhitenoiseProductAnalyticsTrackStatus::Queued => Self::Queued,
            WhitenoiseProductAnalyticsTrackStatus::IgnoredDisabled => Self::IgnoredDisabled,
            WhitenoiseProductAnalyticsTrackStatus::IgnoredUnconfigured => Self::IgnoredUnconfigured,
        }
    }
}

#[frb]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProductAnalyticsFlushStatus {
    Flushed,
    NothingToFlush,
    Disabled,
    Unconfigured,
    TimedOut,
}

impl From<WhitenoiseProductAnalyticsFlushStatus> for ProductAnalyticsFlushStatus {
    fn from(status: WhitenoiseProductAnalyticsFlushStatus) -> Self {
        match status {
            WhitenoiseProductAnalyticsFlushStatus::Flushed => Self::Flushed,
            WhitenoiseProductAnalyticsFlushStatus::NothingToFlush => Self::NothingToFlush,
            WhitenoiseProductAnalyticsFlushStatus::Disabled => Self::Disabled,
            WhitenoiseProductAnalyticsFlushStatus::Unconfigured => Self::Unconfigured,
            WhitenoiseProductAnalyticsFlushStatus::TimedOut => Self::TimedOut,
        }
    }
}

#[frb]
pub fn product_analytics_consent_version() -> String {
    PRODUCT_ANALYTICS_CONSENT_VERSION.to_string()
}

#[frb]
pub async fn product_analytics_settings() -> Result<ProductAnalyticsSettings, ApiError> {
    let whitenoise = wn()?;
    let settings = whitenoise.product_analytics_settings().await?;
    Ok(settings.into())
}

#[frb]
pub async fn set_product_analytics_enabled(
    enabled: bool,
    consent_version: String,
) -> Result<ProductAnalyticsSettings, ApiError> {
    let whitenoise = wn()?;
    let settings = whitenoise
        .set_product_analytics_enabled(enabled, consent_version)
        .await?;
    Ok(settings.into())
}

#[frb]
pub async fn track_product_analytics_event(
    event: ProductAnalyticsEvent,
) -> Result<ProductAnalyticsTrackStatus, ApiError> {
    let whitenoise = wn()?;
    let status = whitenoise
        .track_product_analytics_event(event.into())
        .await?;
    Ok(status.into())
}

#[frb]
pub async fn flush_product_analytics() -> Result<ProductAnalyticsFlushStatus, ApiError> {
    let whitenoise = wn()?;
    let status = whitenoise.flush_product_analytics().await?;
    Ok(status.into())
}
