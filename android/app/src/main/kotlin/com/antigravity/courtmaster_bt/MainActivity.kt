package com.antigravity.courtmaster_bt

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.antigravity.courtmaster_bt/volume_keys"
    private var methodChannel: MethodChannel? = null

    // Configuration des touches
    private var player1KeyCode: Int = KeyEvent.KEYCODE_VOLUME_UP
    private var player2KeyCode: Int = KeyEvent.KEYCODE_VOLUME_DOWN
    private var isInterceptionEnabled: Boolean = false
    private var listeningMode: Int = 0 // 0: None, 1: Player 1, 2: Player 2

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateConfig" -> {
                    player1KeyCode = call.argument<Int>("p1") ?: player1KeyCode
                    player2KeyCode = call.argument<Int>("p2") ?: player2KeyCode
                    isInterceptionEnabled = call.argument<Boolean>("enabled") ?: isInterceptionEnabled
                    result.success(null)
                }
                "startListening" -> {
                    listeningMode = call.argument<Int>("player") ?: 0
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // Mode Apprentissage (Listening)
        if (listeningMode > 0) {
            val player = listeningMode
            listeningMode = 0 // Reset après capture
            methodChannel?.invokeMethod("onKeyCaptured", mapOf("player" to player, "keyCode" to keyCode))
            return true // Consommer pour éviter des actions indésirables pendant l'apprentissage
        }

        // Interception normale
        if (isInterceptionEnabled) {
            when (keyCode) {
                player1KeyCode -> {
                    methodChannel?.invokeMethod("onVolumeKey", mapOf("key" to "P1", "event" to "DOWN"))
                    return true
                }
                player2KeyCode -> {
                    methodChannel?.invokeMethod("onVolumeKey", mapOf("key" to "P2", "event" to "DOWN"))
                    return true
                }
            }
        }
        
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (isInterceptionEnabled && listeningMode == 0) {
            when (keyCode) {
                player1KeyCode -> {
                    methodChannel?.invokeMethod("onVolumeKey", mapOf("key" to "P1", "event" to "UP"))
                    return true
                }
                player2KeyCode -> {
                    methodChannel?.invokeMethod("onVolumeKey", mapOf("key" to "P2", "event" to "UP"))
                    return true
                }
            }
        }
        return super.onKeyUp(keyCode, event)
    }
}
