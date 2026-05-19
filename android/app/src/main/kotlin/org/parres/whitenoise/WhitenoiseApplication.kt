package org.parres.whitenoise

import android.app.Application
import android.util.Log
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import io.crates.keyring.Keyring
import io.flutter.embedding.engine.FlutterEngine

class WhitenoiseApplication : Application(), FlutterForegroundTaskLifecycleListener {
    override fun onCreate() {
        super.onCreate()
        FlutterForegroundTaskPlugin.addTaskLifecycleListener(this)
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

    override fun onEngineCreate(flutterEngine: FlutterEngine?) {
        if (flutterEngine == null) return

        try {
            flutterEngine.plugins.add(AndroidSignerPlugin())
            flutterEngine.plugins.add(AndroidPlayServicesPlugin())
            flutterEngine.plugins.add(AndroidPushNotificationsPlugin())
        } catch (t: Exception) {
            Log.e(TAG, "onEngineCreate: failed to register app plugins", t)
        }
    }

    override fun onTaskStart(starter: FlutterForegroundTaskStarter) {}

    override fun onTaskRepeatEvent() {}

    override fun onTaskDestroy() {}

    override fun onEngineWillDestroy() {}

    companion object {
        private const val TAG = "WhitenoiseApp"
    }
}
