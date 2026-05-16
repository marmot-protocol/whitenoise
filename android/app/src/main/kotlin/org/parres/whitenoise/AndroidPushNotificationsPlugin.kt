package org.parres.whitenoise

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.pravera.flutter_foreground_task.models.ForegroundServiceAction
import com.pravera.flutter_foreground_task.models.ForegroundServiceStatus
import com.pravera.flutter_foreground_task.service.ForegroundService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class AndroidPushNotificationsPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        AndroidPushNotificationBridge.attach(channel)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        AndroidPushNotificationBridge.detach(channel)
        context = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        when (call.method) {
            METHOD_GET_PROVIDER_PUSH_TOKEN -> getProviderPushToken(result)
            METHOD_REQUEST_NOTIFICATION_PERMISSION -> result.success(true)
            else -> result.notImplemented()
        }
    }

    private fun getProviderPushToken(result: Result) {
        val currentContext = context
        if (currentContext == null) {
            result.success(null)
            return
        }

        val cachedToken = AndroidPushNotificationBridge.lastToken(currentContext)
        if (cachedToken != null) {
            result.success(AndroidPushNotificationBridge.tokenMap(cachedToken))
            return
        }

        try {
            FirebaseApp.initializeApp(currentContext)
            FirebaseMessaging.getInstance().token
                .addOnSuccessListener { token ->
                    AndroidPushNotificationBridge.saveToken(currentContext, token)
                    result.success(AndroidPushNotificationBridge.tokenMap(token))
                }
                .addOnFailureListener { error ->
                    Log.w(TAG, "Fetching FCM registration token failed", error)
                    result.success(null)
                }
        } catch (error: Throwable) {
            Log.w(TAG, "Fetching FCM registration token failed", error)
            result.success(null)
        }
    }

    companion object {
        private const val TAG = "WnPushPlugin"
        private const val CHANNEL_NAME = "org.parres.whitenoise/push_notifications"
        private const val METHOD_GET_PROVIDER_PUSH_TOKEN = "getProviderPushToken"
        private const val METHOD_REQUEST_NOTIFICATION_PERMISSION = "requestNotificationPermission"
    }
}

object AndroidPushNotificationBridge {
    private const val TAG = "WnPushBridge"
    private const val PREFS_NAME = "org.parres.whitenoise.push_notifications"
    private const val KEY_FCM_TOKEN = "fcm_token"
    private const val METHOD_PROVIDER_PUSH_TOKEN_UPDATED = "providerPushTokenUpdated"

    private var channel: MethodChannel? = null

    fun attach(channel: MethodChannel) {
        this.channel = channel
    }

    fun detach(channel: MethodChannel) {
        if (this.channel == channel) {
            this.channel = null
        }
    }

    fun tokenMap(token: String): Map<String, String> =
        mapOf(
            "platform" to "fcm",
            "rawToken" to token,
        )

    fun saveToken(context: Context, token: String) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_FCM_TOKEN, token)
            .apply()
    }

    fun lastToken(context: Context): String? =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_FCM_TOKEN, null)
            ?.takeIf { it.isNotBlank() }

    fun publishToken(token: String) {
        channel?.invokeMethod(METHOD_PROVIDER_PUSH_TOKEN_UPDATED, tokenMap(token))
    }

    fun handleBlankPushWake(context: Context) {
        try {
            val intent = Intent(context, ForegroundService::class.java)
            ForegroundServiceStatus.setData(context, ForegroundServiceAction.RESTART)
            ContextCompat.startForegroundService(context, intent)
        } catch (error: Throwable) {
            Log.w(TAG, "Failed to wake foreground notification task", error)
        }
    }
}
