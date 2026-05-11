package com.example.nfc_cloner

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.example.nfc_cloner/hce"
    private val prefName = "nfc_hce_prefs"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(prefName, MODE_PRIVATE)
                when (call.method) {
                    "startEmulation" -> {
                        val uid = call.argument<String>("uid") ?: ""
                        val historical = call.argument<String>("historicalBytes") ?: ""
                        val hiLayer = call.argument<String>("hiLayerResponse") ?: ""
                        prefs.edit()
                            .putBoolean("hce_active", true)
                            .putString("hce_uid", uid)
                            .putString("hce_historical_bytes", historical)
                            .putString("hce_hi_layer_response", hiLayer)
                            .apply()
                        result.success(true)
                    }
                    "stopEmulation" -> {
                        prefs.edit()
                            .putBoolean("hce_active", false)
                            .apply()
                        result.success(true)
                    }
                    "isEmulationActive" -> {
                        result.success(prefs.getBoolean("hce_active", false))
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
