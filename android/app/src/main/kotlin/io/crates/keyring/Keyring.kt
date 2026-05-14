package io.crates.keyring

import android.content.Context

class Keyring {
    companion object {
        init {
            System.loadLibrary("whitenoise_frb")
        }

        external fun initializeNdkContext(context: Context)
    }
}
