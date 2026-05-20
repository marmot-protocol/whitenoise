pub mod api;

#[cfg(any(target_os = "ios", target_os = "macos"))]
mod ios_keyring;

#[cfg(not(any(target_os = "ios", target_os = "macos")))]
mod ios_keyring {
    pub(crate) fn install_ios_keyring_store_if_needed() -> Result<(), String> {
        Ok(())
    }
}

// Include the generated bridge code
mod frb_generated;
pub use frb_generated::*;
