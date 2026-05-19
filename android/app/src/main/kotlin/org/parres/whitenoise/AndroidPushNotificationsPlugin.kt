package org.parres.whitenoise

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.pravera.flutter_foreground_task.models.ForegroundServiceAction
import com.pravera.flutter_foreground_task.models.ForegroundServiceStatus
import com.pravera.flutter_foreground_task.service.ForegroundService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class AndroidPushNotificationsPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: Result? = null

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

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity(completePendingPermission = false)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        when (call.method) {
            METHOD_GET_PROVIDER_PUSH_TOKEN -> getProviderPushToken(result)
            METHOD_REQUEST_NOTIFICATION_PERMISSION -> requestNotificationPermission(result)
            else -> result.notImplemented()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE_POST_NOTIFICATIONS) return false
        val granted =
            permissions.contains(Manifest.permission.POST_NOTIFICATIONS) &&
                grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
        return true
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
        } catch (error: Exception) {
            Log.w(TAG, "Fetching FCM registration token failed", error)
            result.success(null)
        }
    }

    private fun requestNotificationPermission(result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }

        val currentContext = context
        if (currentContext == null) {
            result.success(false)
            return
        }

        if (
            ContextCompat.checkSelfPermission(
                currentContext,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }

        val currentActivity = activity
        if (currentActivity == null) {
            result.success(false)
            return
        }

        if (pendingPermissionResult != null) {
            result.error(
                "permission_request_in_progress",
                "Notification permission request already in progress",
                null,
            )
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            currentActivity,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_CODE_POST_NOTIFICATIONS,
        )
    }

    private fun detachActivity(completePendingPermission: Boolean = true) {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
        if (completePendingPermission) {
            pendingPermissionResult?.success(false)
            pendingPermissionResult = null
        }
    }

    companion object {
        private const val TAG = "WnPushPlugin"
        private const val CHANNEL_NAME = "org.parres.whitenoise/push_notifications"
        private const val METHOD_GET_PROVIDER_PUSH_TOKEN = "getProviderPushToken"
        private const val METHOD_REQUEST_NOTIFICATION_PERMISSION = "requestNotificationPermission"
        private const val REQUEST_CODE_POST_NOTIFICATIONS = 2401
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
        } catch (error: Exception) {
            Log.w(TAG, "Failed to wake foreground notification task", error)
        }
    }
}
