use crate::api::{ApiError, wn};
use flutter_rust_bridge::frb;

#[frb]
pub async fn resume_after_background() -> Result<(), ApiError> {
    let whitenoise = wn().await?;
    whitenoise.resume_after_background().await?;
    Ok(())
}
