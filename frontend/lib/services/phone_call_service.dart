import 'package:flutter/services.dart';

enum CallState { idle, answered }

// Global storage for last call duration (persists across widget lifecycle)
class _CallDurationStore {
  static int? lastDuration;
  static DateTime? lastDurationTime;
}

class PhoneCallService {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.telecaller_app/phone',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.telecaller_app/phone_events',
  );

  static CallState _state = CallState.idle;
  static int? _offhookTime;
  static bool _callAnswered = false;
  static bool _callEndedAlready = false;
  static Function(String phone, int duration)? _callback;
  static bool _listenerInitialized = false;

  static void initialize(Function(String phone, int duration) callback) {
    _callback = callback;

    // Only set up listener once
    if (_listenerInitialized) return;
    _listenerInitialized = true;

    _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is! Map) return;
      final type = event['event'] as String?;
      final phone = event['phoneNumber'] as String? ?? '';
      final duration = event['duration'] as int? ?? 0;

      print(
        'PhoneCallService: Event=$type, Phone=$phone, Duration=$duration, State=$_state',
      );

      if (type == 'callAnswered') {
        // Set answer time ONLY ONCE per call
        if (!_callAnswered) {
          _callAnswered = true;
          _offhookTime = DateTime.now().millisecondsSinceEpoch;
          print(
            'PhoneCallService: OFFHOOK recorded at $_offhookTime (first time)',
          );
        } else {
          print('PhoneCallService: Ignoring duplicate OFFHOOK event');
        }
      } else if (type == 'callEnded') {
        // Emit duration event ONLY ONCE per call
        if (!_callEndedAlready) {
          _callEndedAlready = true;
          print(
            'PhoneCallService: Call ended - Duration=$duration seconds (first time)',
          );

          // Store in global cache (persists even if widget unmounts)
          // Use timestamp to track when duration was cached
          _CallDurationStore.lastDuration = duration;
          _CallDurationStore.lastDurationTime = DateTime.now();
          print(
            'PhoneCallService: Stored in cache - duration=$duration at ${_CallDurationStore.lastDurationTime}',
          );

          _callback?.call(phone, duration);
        } else {
          print(
            'PhoneCallService: Ignoring duplicate IDLE event (already emitted duration=$duration)',
          );
        }
        _reset();
      }
    });
  }

  static Future<bool> makeCall(String phone) async {
    _reset();
    try {
      // First, notify Android that we're making an outgoing call
      // This ensures the CallTrackingReceiver knows this is outgoing
      try {
        await _methodChannel.invokeMethod('markOutgoingCall', {
          'phoneNumber': phone,
        });
        print('PhoneCallService: Marked call as outgoing for $phone');
      } catch (e) {
        print(
          'PhoneCallService: Warning - could not mark call as outgoing: $e',
        );
        // Continue anyway - the call will still be made
      }

      // Now make the actual call
      return await _methodChannel.invokeMethod('callPhone', {
            'phoneNumber': phone,
          }) ??
          false;
    } catch (e) {
      print('PhoneCallService: Error making call: $e');
      return false;
    }
  }

  static void _reset() {
    _state = CallState.idle;
    _offhookTime = null;
    _callAnswered = false;
    _callEndedAlready = false;
  }

  // Get cached duration (for UI that mounts after call ends)
  // Returns duration if it was cached within last 30 seconds
  static int? getCachedDuration() {
    if (_CallDurationStore.lastDuration != null &&
        _CallDurationStore.lastDurationTime != null) {
      final ageMs =
          DateTime.now()
              .difference(_CallDurationStore.lastDurationTime!)
              .inMilliseconds;

      // Only return if cached within last 30 seconds
      if (ageMs < 30000) {
        print(
          'PhoneCallService: Returning cached duration=${_CallDurationStore.lastDuration} (age=${ageMs}ms)',
        );
        return _CallDurationStore.lastDuration;
      } else {
        print(
          'PhoneCallService: Cached duration too old (${ageMs}ms), ignoring',
        );
      }
    }
    return null;
  }

  // Clear cache
  static void clearCache() {
    _CallDurationStore.lastDuration = null;
    _CallDurationStore.lastDurationTime = null;
  }
}
