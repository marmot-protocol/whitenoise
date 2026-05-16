package org.parres.whitenoise

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class Mip05FirebaseMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        AndroidPushNotificationBridge.saveToken(applicationContext, token)
        AndroidPushNotificationBridge.publishToken(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        if (message.notification != null) return
        Log.d(TAG, "Received MIP-05 wake push with ${message.data.size} data keys")
        AndroidPushNotificationBridge.handleBlankPushWake(applicationContext)
    }

    companion object {
        private const val TAG = "Mip05FcmService"
    }
}
