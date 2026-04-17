package org.parres.whitenoise

import android.app.Application
import io.crates.keyring.Keyring

class WhitenoiseApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Hand the Android Context to the Rust keyring crate. Runs on every
        // process start (Activity, Service, or Receiver entry points), so the
        // foreground service can reach Rust even when the app was launched
        // headlessly by RebootReceiver / MY_PACKAGE_REPLACED.
        Keyring.initializeNdkContext(applicationContext)
    }
}
