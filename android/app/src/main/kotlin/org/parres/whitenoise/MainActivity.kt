package org.parres.whitenoise

import android.content.Context
import android.os.Bundle
import io.crates.keyring.Keyring
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    companion object {
        // TODO: Remove migration cleanup in the next release.
        private const val MIGRATION_PREFS = "org.parres.whitenoise.migration"
        private const val KEY_CLEANED_FGS_PREFS = "cleaned_fgs_prefs_v1"

        private val FOREGROUND_TASK_PREFS = listOf(
            "com.pravera.flutter_foreground_task.prefs.FOREGROUND_SERVICE_STATUS",
            "com.pravera.flutter_foreground_task.prefs.FOREGROUND_SERVICE_TYPES",
            "com.pravera.flutter_foreground_task.prefs.FOREGROUND_TASK_OPTIONS",
            "com.pravera.flutter_foreground_task.prefs.NOTIFICATION_OPTIONS",
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        cleanForegroundTaskPrefs()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Keyring.initializeNdkContext(applicationContext)
        flutterEngine.plugins.add(AndroidSignerPlugin())
    }

    private fun cleanForegroundTaskPrefs() {
        val migrationPrefs = getSharedPreferences(MIGRATION_PREFS, Context.MODE_PRIVATE)
        if (migrationPrefs.getBoolean(KEY_CLEANED_FGS_PREFS, false)) return

        for (prefsName in FOREGROUND_TASK_PREFS) {
            getSharedPreferences(prefsName, Context.MODE_PRIVATE).edit().clear().commit()
        }

        migrationPrefs.edit().putBoolean(KEY_CLEANED_FGS_PREFS, true).commit()
    }
}
