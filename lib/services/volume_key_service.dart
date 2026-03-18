import 'dart:async';
import 'package:flutter/services.dart';

enum VolumeKey { TeamA, TeamB }
enum KeyEventType { DOWN, UP }
enum GestureType { singleTap, doubleTap, longPress }

class VolumeKeyService {
  static const _channel = MethodChannel('com.antigravity.courtmaster_bt/volume_keys');
  
  // Mode 2 boutons (classique)
  final Function(VolumeKey key, bool isLongPress)? onKeyAction;
  // Mode 1 bouton (gestes)
  final Function(GestureType gesture)? onGesture;
  // Capture de touches (paramètres)
  final Function(int teamIndex, int keyCode)? onKeyCaptured;
  
  bool oneButtonMode;
  
  // --- État interne pour le mode 2 boutons ---
  static const _longPressDuration2B = Duration(milliseconds: 600);
  Timer? _longPressTimer;
  bool _longPressTriggered = false;

  // --- État interne pour le mode 1 bouton ---
  static const _longPressDuration1B = Duration(milliseconds: 600);
  static const _doubleClickWindow = Duration(milliseconds: 400);
  bool _isKeyDown = false;
  Timer? _longPressTimer1B;
  bool _longPressTriggered1B = false;
  Timer? _doubleClickTimer;
  int _clickCount = 0;

  VolumeKeyService({
    this.onKeyAction, 
    this.onKeyCaptured, 
    this.onGesture,
    this.oneButtonMode = false,
  }) {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    if (call.method == "onVolumeKey") {
      final String keyStr = call.arguments['key'];
      final String eventStr = call.arguments['event'];
      
      final key = (keyStr == "P1") ? VolumeKey.TeamA : VolumeKey.TeamB;
      final event = (eventStr == "DOWN") ? KeyEventType.DOWN : KeyEventType.UP;

      if (oneButtonMode) {
        _handleOneButtonEvent(event);
      } else {
        _handleTwoButtonEvent(key, event);
      }
    } else if (call.method == "onKeyCaptured") {
      final int player = call.arguments['player'];
      final int keyCode = call.arguments['keyCode'];
      onKeyCaptured?.call(player, keyCode);
    }
  }

  // ============================
  // MODE 2 BOUTONS (inchangé)
  // ============================
  void _handleTwoButtonEvent(VolumeKey key, KeyEventType event) {
    if (event == KeyEventType.DOWN) {
      _longPressTriggered = false;
      _longPressTimer?.cancel();
      _longPressTimer = Timer(_longPressDuration2B, () {
        _longPressTriggered = true;
        onKeyAction?.call(key, true); // Long press
      });
    } else {
      _longPressTimer?.cancel();
      if (!_longPressTriggered) {
        onKeyAction?.call(key, false); // Short press
      }
    }
  }

  // ============================
  // MODE 1 BOUTON (nouveau)
  // ============================
  void _handleOneButtonEvent(KeyEventType event) {
    if (event == KeyEventType.DOWN) {
      if (_isKeyDown) return; // Ignorer les répétitions
      _isKeyDown = true;
      _longPressTriggered1B = false;

      // Démarrer le timer d'appui long
      _longPressTimer1B?.cancel();
      _longPressTimer1B = Timer(_longPressDuration1B, () {
        _longPressTriggered1B = true;
        _doubleClickTimer?.cancel();
        _clickCount = 0;
        onGesture?.call(GestureType.longPress);
      });
    } else {
      // KEY_UP
      _isKeyDown = false;
      _longPressTimer1B?.cancel();

      if (_longPressTriggered1B) {
        // L'appui long a déjà été déclenché, on ignore le relâchement
        return;
      }

      // C'est un clic court
      _clickCount++;

      if (_clickCount == 1) {
        // Premier clic : attendre pour voir si un 2ème arrive
        _doubleClickTimer?.cancel();
        _doubleClickTimer = Timer(_doubleClickWindow, () {
          // Pas de 2ème clic → simple clic
          _clickCount = 0;
          onGesture?.call(GestureType.singleTap);
        });
      } else if (_clickCount >= 2) {
        // Deuxième clic → double clic !
        _doubleClickTimer?.cancel();
        _clickCount = 0;
        onGesture?.call(GestureType.doubleTap);
      }
    }
  }

  void dispose() {
    _longPressTimer?.cancel();
    _longPressTimer1B?.cancel();
    _doubleClickTimer?.cancel();
  }
}
