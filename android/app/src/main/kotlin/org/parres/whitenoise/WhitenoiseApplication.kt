package org.parres.whitenoise

import android.app.Application
import android.util.Log
import io.crates.keyring.Keyring

class WhitenoiseApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Hand the Android Context to the Rust keyring crate. Runs on every
        // process start (Activity, Service, or Receiver entry points), so
        // background components can reach Rust even when launched headlessly
        // by RebootReceiver / MY_PACKAGE_REPLACED.
        try {
            Keyring.initializeNdkContext(applicationContext)
        } catch (t: Throwable) {
            Log.e(TAG, "onCreate: Keyring.initializeNdkContext failed", t)
        }
    }

    companion object {
        private const val TAG = "WhitenoiseApp"
    }
}
