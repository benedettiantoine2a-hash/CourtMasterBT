package com.antigravity.courtmaster_bt

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.antigravity.courtmaster_bt/volume_keys"
    private var methodChannel: MethodChannel? = null

    // Configuration des touches (supporte plusieurs touches par équipe)
    private var teamAKeyCodes: Set<Int> = setOf(KeyEvent.KEYCODE_VOLUME_UP)
    private var teamBKeyCodes: Set<Int> = setOf(KeyEvent.KEYCODE_VOLUME_DOWN)
    private var isInterceptionEnabled: Boolean = false
    private var listeningMode: Int = 0 // 0: None, 1: Team A, 2: Team B
    
    // Anti-parasite : après une capture, on ignore TOUTES les touches pendant ce délai
    private var captureBlockedUntil: Long = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateConfig" -> {
                    val p1List = call.argument<List<Int>>("p1")
                    val p2List = call.argument<List<Int>>("p2")
                    
                    if (p1List != null) teamAKeyCodes = p1List.toSet()
                    if (p2List != null) teamBKeyCodes = p2List.toSet()
                    
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
        val now = System.currentTimeMillis()
        
        // Anti-parasite : on bloque TOUT pendant la fenêtre de protection
        if (now < captureBlockedUntil) {
            return true // Avaler la touche silencieusement
        }

        // Mode Apprentissage (Listening)
        if (listeningMode > 0) {
            val player = listeningMode
            listeningMode = 0 // Reset après capture
            captureBlockedUntil = now + 1000 // Bloquer pendant 1 seconde
            methodChannel?.invokeMethod("onKeyCaptured", mapOf("player" to player, "keyCode" to keyCode))
            return true 
        }

        // Interception normale (pendant les matchs)
        if (isInterceptionEnabled) {
            if (teamAKeyCodes.contains(keyCode)) {
                methodChannel?.invokeMethod("onVolumeKey", mapOf("key" to "P1", "event" to "DOWN"))
                return true
            } else if (teamBKeyCodes.contains(keyCode)) {
                methodChannel?.invokeMethod("onVolumeKey", mapOf("key" to "P2", "event" to "DOWN"))
                return true
            }
        }
        
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        val now = System.currentTimeMillis()
        
        // Anti-parasite : bloquer aussi les relâchements parasites
        if (now < captureBlockedUntil) {
            return true
        }

        if (isInterceptionEnabled && listeningMode == 0) {
            if (teamAKeyCodes.contains(keyCode)) {
                methodChannel?.invokeMethod("onVolumeKey", mapOf("key" to "P1", "event" to "UP"))
                return true
            } else if (teamBKeyCodes.contains(keyCode)) {
                methodChannel?.invokeMethod("onVolumeKey", mapOf("key" to "P2", "event" to "UP"))
                return true
            }
        }
        return super.onKeyUp(keyCode, event)
    }
}
