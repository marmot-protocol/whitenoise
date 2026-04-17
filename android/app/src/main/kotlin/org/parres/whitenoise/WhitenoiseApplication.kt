package org.parres.whitenoise

import android.app.Application
import android.util.Log
import io.crates.keyring.Keyring

class WhitenoiseApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Hand the Android Context to the Rust keyring crate. Runs on every
        // process start (Activity, Service, or Receiver entry points), so the
        // foreground service can reach Rust even when the app was launched
        // headlessly by RebootReceiver / MY_PACKAGE_REPLACED.
        // SPIKE: logging here verifies the subclass is actually being loaded
        // in headless process starts. Remove when the real headless
        // subscription lands (TODO #488).
        Log.i(TAG, "onCreate: initializing NDK context")
        try {
            Keyring.initializeNdkContext(applicationContext)
            Log.i(TAG, "onCreate: NDK context initialized")
        } catch (t: Throwable) {
            Log.e(TAG, "onCreate: Keyring.initializeNdkContext failed", t)
        }
    }

    companion object {
        private const val TAG = "WhitenoiseApp"
    }
}
