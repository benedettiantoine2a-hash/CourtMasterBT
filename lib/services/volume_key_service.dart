import 'dart:async';
import 'package:flutter/services.dart';

enum VolumeKey { UP, DOWN }
enum KeyEventType { DOWN, UP }

class VolumeKeyService {
  static const _channel = MethodChannel('com.antigravity.courtmaster_bt/volume_keys');
  
  final Function(VolumeKey key, bool isLongPress) onKeyAction;
  
  DateTime? _lastDownTime;
  VolumeKey? _currentKey;
  static const _longPressDuration = Duration(milliseconds: 600);
  Timer? _longPressTimer;
  bool _longPressTriggered = false;

  VolumeKeyService({required this.onKeyAction}) {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<void> _handleMethod(MethodCall call) async {
    if (call.method == "onVolumeKey") {
      final String keyStr = call.arguments['key'];
      final String eventStr = call.arguments['event'];
      
      final key = (keyStr == "UP") ? VolumeKey.UP : VolumeKey.DOWN;
      final event = (eventStr == "DOWN") ? KeyEventType.DOWN : KeyEventType.UP;

      if (event == KeyEventType.DOWN) {
        _currentKey = key;
        _lastDownTime = DateTime.now();
        _longPressTriggered = false;
        
        _longPressTimer?.cancel();
        _longPressTimer = Timer(_longPressDuration, () {
          _longPressTriggered = true;
          onKeyAction(key, true);
        });
      } else {
        _longPressTimer?.cancel();
        if (!_longPressTriggered) {
          onKeyAction(key, false);
        }
        _currentKey = null;
      }
    }
  }
}
