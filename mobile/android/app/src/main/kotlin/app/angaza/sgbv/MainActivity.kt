package app.angaza.sgbv

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "app.angaza.sgbv/channel"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        // Optional: handle calls from Dart
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "collapse_panels" -> { /* no-op on phones without privileges */ result.success(null) }
                else -> result.notImplemented()
            }
        }
        // If app launched with SOS extra, notify Dart once engine is ready
        maybeNotifyExternalTrigger(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        maybeNotifyExternalTrigger(intent)
    }

    private fun maybeNotifyExternalTrigger(intent: Intent?) {
        if (intent == null) return
        val fromExtra = intent.getBooleanExtra("sos", false)
        val fromDeepLink = intent.data?.scheme == "angaza" && intent.data?.host == "sos"
        if (fromExtra || fromDeepLink) {
            methodChannel?.invokeMethod("external_sos_trigger", null)
        }
    }
}
