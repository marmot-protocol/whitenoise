package org.parres.whitenoise

import android.content.Context
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class AndroidPlayServicesPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null

    companion object {
        private const val CHANNEL_NAME = "org.parres.whitenoise/android_play_services"
        private const val METHOD_GET_AVAILABILITY = "getAvailability"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result,
    ) {
        when (call.method) {
            METHOD_GET_AVAILABILITY -> {
                val statusCode = getAvailabilityStatusCode()
                result.success(
                    mapOf(
                        "isAvailable" to (statusCode == ConnectionResult.SUCCESS),
                        "statusCode" to statusCode,
                    ),
                )
            }

            else -> result.notImplemented()
        }
    }

    private fun getAvailabilityStatusCode(): Int {
        val currentContext = context ?: return ConnectionResult.SERVICE_MISSING
        return GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(currentContext)
    }
}
