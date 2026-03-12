package com.antigravity.courtmaster_bt

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.antigravity.courtmaster_bt/volume_keys"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> {
                methodChannel?.invokeMethod("onVolumeKey", mapOf("key" to "UP", "event" to "DOWN"))
                return true
            }
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                methodChannel?.invokeMethod("onVolumeKey", mapOf("key" to "DOWN", "event" to "DOWN"))
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> {
                methodChannel?.invokeMethod("onVolumeKey", mapOf("key" to "UP", "event" to "UP"))
                return true
            }
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                methodChannel?.invokeMethod("onVolumeKey", mapOf("key" to "DOWN", "event" to "UP"))
                return true
            }
        }
        return super.onKeyUp(keyCode, event)
    }
}
