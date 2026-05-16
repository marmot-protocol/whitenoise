use std::any::Any;
use std::collections::HashMap;
use std::fmt;
use std::sync::Arc;

use apple_native_keyring_store::protected::{AccessPolicy, Cred, Store as ProtectedStore};
use keyring_core::api::{CredentialApi, CredentialStoreApi};
use keyring_core::{Credential, CredentialPersistence, CredentialStore, Entry, Error, Result};

const WHITENOISE_KEYRING_SERVICE_ID: &str = "com.whitenoise.app";
const AFTER_FIRST_UNLOCK_SERVICE_SUFFIX: &str = ".after-first-unlock";

pub(crate) fn install_ios_keyring_store_if_needed() -> std::result::Result<(), String> {
    #[cfg(target_os = "ios")]
    {
        install_after_first_unlock_keyring_store(None).map_err(|e| e.to_string())
    }

    #[cfg(not(target_os = "ios"))]
    {
        Ok(())
    }
}

#[cfg(target_os = "ios")]
#[unsafe(no_mangle)]
pub extern "C" fn wn_install_ios_background_keyring_store() -> bool {
    install_after_first_unlock_keyring_store(None).is_ok()
}

#[cfg(target_os = "ios")]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn wn_install_ios_background_keyring_store_with_access_group(
    access_group_ptr: *const u8,
    access_group_len: usize,
) -> bool {
    let access_group = if access_group_ptr.is_null() || access_group_len == 0 {
        None
    } else {
        let bytes = unsafe { std::slice::from_raw_parts(access_group_ptr, access_group_len) };
        match std::str::from_utf8(bytes) {
            Ok(value) if !value.is_empty() => Some(value.to_string()),
            _ => None,
        }
    };
    install_after_first_unlock_keyring_store(access_group).is_ok()
}

#[cfg(target_os = "ios")]
fn install_after_first_unlock_keyring_store(access_group: Option<String>) -> Result<()> {
    keyring_core::set_default_store(AfterFirstUnlockMigratingStore::new(access_group)?);
    Ok(())
}

struct AfterFirstUnlockMigratingStore {
    fallback: Arc<CredentialStore>,
    access_group: Option<String>,
}

impl AfterFirstUnlockMigratingStore {
    fn new(access_group: Option<String>) -> Result<Arc<Self>> {
        let fallback = match access_group.as_deref() {
            Some(access_group) => {
                let mut config = HashMap::new();
                config.insert("access-group", access_group);
                ProtectedStore::new_with_configuration(&config)?
            }
            None => ProtectedStore::new()?,
        };
        Ok(Arc::new(Self {
            fallback,
            access_group,
        }))
    }

    fn primary_entry(&self, service: &str, user: &str) -> Result<Entry> {
        Cred::build(
            &primary_service_id(service),
            user,
            AccessPolicy::AfterFirstUnlockThisDeviceOnly,
            self.access_group.clone(),
            false,
        )
    }
}

impl fmt::Debug for AfterFirstUnlockMigratingStore {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("AfterFirstUnlockMigratingStore").finish()
    }
}

impl CredentialStoreApi for AfterFirstUnlockMigratingStore {
    fn vendor(&self) -> String {
        "White Noise iOS protected store".to_string()
    }

    fn id(&self) -> String {
        "White Noise iOS AfterFirstUnlockThisDeviceOnly migrating store".to_string()
    }

    fn build(
        &self,
        service: &str,
        user: &str,
        modifiers: Option<&HashMap<&str, &str>>,
    ) -> Result<Entry> {
        if service != WHITENOISE_KEYRING_SERVICE_ID {
            return self.fallback.build(service, user, modifiers);
        }

        Ok(Entry::new_with_credential(Arc::new(
            AfterFirstUnlockMigratingCredential {
                service: service.to_string(),
                user: user.to_string(),
                primary: self.primary_entry(service, user)?,
                legacy: self.fallback.build(service, user, modifiers)?,
            },
        )))
    }

    fn search(&self, spec: &HashMap<&str, &str>) -> Result<Vec<Entry>> {
        self.fallback.search(spec)
    }

    fn as_any(&self) -> &dyn Any {
        self
    }

    fn persistence(&self) -> CredentialPersistence {
        CredentialPersistence::UntilDelete
    }

    fn debug_fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Debug::fmt(self, f)
    }
}

#[derive(Debug)]
struct AfterFirstUnlockMigratingCredential {
    service: String,
    user: String,
    primary: Entry,
    legacy: Entry,
}

impl AfterFirstUnlockMigratingCredential {
    fn delete_legacy_best_effort(&self) {
        match self.legacy.delete_credential() {
            Ok(()) | Err(Error::NoEntry) => {}
            Err(err) => {
                tracing::warn!(
                    target: "whitenoise::ios_keyring",
                    service = %self.service,
                    user = %self.user,
                    error = %err,
                    "Failed to delete legacy keychain entry after migration"
                );
            }
        }
    }

    fn migrate_legacy_secret(&self, secret: &[u8]) {
        match self.primary.set_secret(secret) {
            Ok(()) => self.delete_legacy_best_effort(),
            Err(err) => {
                tracing::warn!(
                    target: "whitenoise::ios_keyring",
                    service = %self.service,
                    user = %self.user,
                    error = %err,
                    "Failed to migrate keychain entry to AfterFirstUnlockThisDeviceOnly"
                );
            }
        }
    }
}

impl CredentialApi for AfterFirstUnlockMigratingCredential {
    fn set_secret(&self, secret: &[u8]) -> Result<()> {
        self.primary.set_secret(secret)?;
        self.delete_legacy_best_effort();
        Ok(())
    }

    fn get_secret(&self) -> Result<Vec<u8>> {
        match self.primary.get_secret() {
            Ok(secret) => Ok(secret),
            Err(Error::NoEntry) => {
                let secret = self.legacy.get_secret()?;
                self.migrate_legacy_secret(&secret);
                Ok(secret)
            }
            Err(err) => Err(err),
        }
    }

    fn delete_credential(&self) -> Result<()> {
        let primary = self.primary.delete_credential();
        let legacy = self.legacy.delete_credential();

        match (primary, legacy) {
            (Ok(()), _) | (_, Ok(())) => Ok(()),
            (Err(Error::NoEntry), Err(Error::NoEntry)) => Err(Error::NoEntry),
            (Err(err), Err(Error::NoEntry)) | (Err(Error::NoEntry), Err(err)) => Err(err),
            (Err(primary_err), Err(_legacy_err)) => Err(primary_err),
        }
    }

    fn get_credential(&self) -> Result<Option<Arc<Credential>>> {
        Ok(None)
    }

    fn get_specifiers(&self) -> Option<(String, String)> {
        Some((self.service.clone(), self.user.clone()))
    }

    fn as_any(&self) -> &dyn Any {
        self
    }

    fn debug_fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Debug::fmt(self, f)
    }
}

fn primary_service_id(service: &str) -> String {
    format!("{service}{AFTER_FIRST_UNLOCK_SERVICE_SUFFIX}")
}

#[cfg(test)]
mod tests {
    use std::sync::Mutex;

    use super::*;

    #[test]
    fn whitenoise_entries_use_after_first_unlock_this_device_only_primary_store() {
        let store = AfterFirstUnlockMigratingStore::new(None).unwrap();
        let entry = store
            .build(WHITENOISE_KEYRING_SERVICE_ID, "account-key", None)
            .unwrap();

        let credential = entry
            .as_any()
            .downcast_ref::<AfterFirstUnlockMigratingCredential>()
            .unwrap();
        let primary = credential.primary.as_any().downcast_ref::<Cred>().unwrap();
        let legacy = credential.legacy.as_any().downcast_ref::<Cred>().unwrap();

        assert_eq!(
            primary.service,
            primary_service_id(WHITENOISE_KEYRING_SERVICE_ID)
        );
        assert_eq!(primary.account, "account-key");
        assert_eq!(
            primary.access_policy,
            AccessPolicy::AfterFirstUnlockThisDeviceOnly
        );
        assert_eq!(legacy.service, WHITENOISE_KEYRING_SERVICE_ID);
        assert_eq!(legacy.access_policy, AccessPolicy::WhenUnlocked);
    }

    #[test]
    fn whitenoise_entries_use_configured_access_group() {
        let access_group = "TEAMID.dev.ipf.whitenoise.staging".to_string();
        let store = AfterFirstUnlockMigratingStore::new(Some(access_group.clone())).unwrap();
        let entry = store
            .build(WHITENOISE_KEYRING_SERVICE_ID, "database-key", None)
            .unwrap();

        let credential = entry
            .as_any()
            .downcast_ref::<AfterFirstUnlockMigratingCredential>()
            .unwrap();
        let primary = credential.primary.as_any().downcast_ref::<Cred>().unwrap();
        let legacy = credential.legacy.as_any().downcast_ref::<Cred>().unwrap();

        assert_eq!(primary.access_group, Some(access_group.clone()));
        assert_eq!(legacy.access_group, Some(access_group));
    }

    #[test]
    fn other_services_keep_default_protected_store_behavior() {
        let store = AfterFirstUnlockMigratingStore::new(None).unwrap();
        let entry = store
            .build("com.example.other", "account-key", None)
            .unwrap();

        let credential = entry.as_any().downcast_ref::<Cred>().unwrap();

        assert_eq!(credential.service, "com.example.other");
        assert_eq!(credential.account, "account-key");
        assert_eq!(credential.access_policy, AccessPolicy::WhenUnlocked);
    }

    #[test]
    fn legacy_secret_is_migrated_to_primary_on_read() {
        let primary = Arc::new(RecordingCredential::default());
        let legacy = Arc::new(RecordingCredential::with_secret(b"secret".to_vec()));
        let credential = AfterFirstUnlockMigratingCredential {
            service: WHITENOISE_KEYRING_SERVICE_ID.to_string(),
            user: "account-key".to_string(),
            primary: Entry::new_with_credential(primary.clone()),
            legacy: Entry::new_with_credential(legacy.clone()),
        };

        assert_eq!(credential.get_secret().unwrap(), b"secret");
        assert_eq!(primary.secret(), Some(b"secret".to_vec()));
        assert!(legacy.was_deleted());
    }

    #[test]
    fn primary_secret_wins_without_touching_legacy() {
        let primary = Arc::new(RecordingCredential::with_secret(b"primary".to_vec()));
        let legacy = Arc::new(RecordingCredential::with_secret(b"legacy".to_vec()));
        let credential = AfterFirstUnlockMigratingCredential {
            service: WHITENOISE_KEYRING_SERVICE_ID.to_string(),
            user: "account-key".to_string(),
            primary: Entry::new_with_credential(primary.clone()),
            legacy: Entry::new_with_credential(legacy.clone()),
        };

        assert_eq!(credential.get_secret().unwrap(), b"primary");
        assert!(!legacy.was_deleted());
    }

    #[derive(Debug, Default)]
    struct RecordingCredential {
        secret: Mutex<Option<Vec<u8>>>,
        deleted: Mutex<bool>,
    }

    impl RecordingCredential {
        fn with_secret(secret: Vec<u8>) -> Self {
            Self {
                secret: Mutex::new(Some(secret)),
                deleted: Mutex::new(false),
            }
        }

        fn secret(&self) -> Option<Vec<u8>> {
            self.secret.lock().unwrap().clone()
        }

        fn was_deleted(&self) -> bool {
            *self.deleted.lock().unwrap()
        }
    }

    impl CredentialApi for RecordingCredential {
        fn set_secret(&self, secret: &[u8]) -> Result<()> {
            *self.secret.lock().unwrap() = Some(secret.to_vec());
            Ok(())
        }

        fn get_secret(&self) -> Result<Vec<u8>> {
            self.secret.lock().unwrap().clone().ok_or(Error::NoEntry)
        }

        fn delete_credential(&self) -> Result<()> {
            *self.deleted.lock().unwrap() = true;
            match self.secret.lock().unwrap().take() {
                Some(_) => Ok(()),
                None => Err(Error::NoEntry),
            }
        }

        fn get_credential(&self) -> Result<Option<Arc<Credential>>> {
            Ok(None)
        }

        fn get_specifiers(&self) -> Option<(String, String)> {
            None
        }

        fn as_any(&self) -> &dyn Any {
            self
        }
    }
}
