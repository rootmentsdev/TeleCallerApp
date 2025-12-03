import 'package:flutter/services.dart';

/// Service to handle phone call tracking and receive call duration updates
class PhoneCallService {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.telecaller_app/phone',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.telecaller_app/phone_events',
  );

  static Stream<dynamic>? _callEventsStream;
  static Function(String phoneNumber, int? duration)? _onCallEndedCallback;

  /// Initialize the phone call service and listen for call events
  static void initialize({
    required Function(String phoneNumber, int? duration) onCallEnded,
  }) {
    _onCallEndedCallback = onCallEnded;
    _startListening();
  }

  /// Start listening to call events from native
  static void _startListening() {
    _callEventsStream = _eventChannel.receiveBroadcastStream();
    _callEventsStream?.listen(
      (dynamic event) {
        print('PhoneCallService: Received event: $event');
        if (event is Map) {
          final eventType = event['event'] as String?;
          print('PhoneCallService: Event type: $eventType');
          if (eventType == 'callEnded') {
            final phoneNumber = event['phoneNumber'] as String? ?? '';
            final durationValue = event['duration'] as int?;
            print(
              'PhoneCallService: Phone: $phoneNumber, Duration value: $durationValue',
            );
            // -1 means null/call not answered
            final duration =
                (durationValue != null && durationValue >= 0)
                    ? durationValue
                    : null;
            print(
              'PhoneCallService: Calling callback with phone: $phoneNumber, duration: $duration',
            );
            _onCallEndedCallback?.call(phoneNumber, duration);
          }
        }
      },
      onError: (error) {
        print('Error listening to call events: $error');
      },
    );
  }

  /// Make a phone call and start tracking
  static Future<bool> makeCall({
    required String phoneNumber,
    String? leadId,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('callPhone', {
        'phoneNumber': phoneNumber,
        'leadId': leadId,
      });
      return result ?? false;
    } catch (e) {
      print('Error making phone call: $e');
      return false;
    }
  }

  /// Dispose the service
  static void dispose() {
    _callEventsStream = null;
    _onCallEndedCallback = null;
  }
}
