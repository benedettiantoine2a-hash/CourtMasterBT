import 'dart:async';
import 'package:flutter/services.dart';

enum VolumeKey { P1, P2 }
enum KeyEventType { DOWN, UP }

class VolumeKeyService {
  static const _channel = MethodChannel('com.antigravity.courtmaster_bt/volume_keys');
  
  final Function(VolumeKey key, bool isLongPress)? onKeyAction;
  final Function(int player, int keyCode)? onKeyCaptured;
  
  VolumeKey? _currentKey;
  static const _longPressDuration = Duration(milliseconds: 600);
  Timer? _longPressTimer;
  bool _longPressTriggered = false;

  VolumeKeyService({this.onKeyAction, this.onKeyCaptured}) {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    if (call.method == "onVolumeKey") {
      final String keyStr = call.arguments['key'];
      final String eventStr = call.arguments['event'];
      
      final key = (keyStr == "P1") ? VolumeKey.P1 : VolumeKey.P2;
      final event = (eventStr == "DOWN") ? KeyEventType.DOWN : KeyEventType.UP;

      if (event == KeyEventType.DOWN) {
        _currentKey = key;
        _longPressTriggered = false;
        
        _longPressTimer?.cancel();
        _longPressTimer = Timer(_longPressDuration, () {
          _longPressTriggered = true;
          onKeyAction?.call(key, true);
        });
      } else {
        _longPressTimer?.cancel();
        if (!_longPressTriggered) {
          onKeyAction?.call(key, false);
        }
        _currentKey = null;
      }
    } else if (call.method == "onKeyCaptured") {
      final int player = call.arguments['player'];
      final int keyCode = call.arguments['keyCode'];
      onKeyCaptured?.call(player, keyCode);
    }
  }
}
