import 'package:flutter/services.dart';

class PhoneCallService {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.telecaller_app/phone',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.telecaller_app/phone_events',
  );

  static Stream<dynamic>? _callEventsStream;
  static Function(String phoneNumber, int? duration)? _onCallEndedCallback;
  static Function(String phoneNumber)? _onCallAnsweredCallback;
  static Function(String phoneNumber)? _onCallStartedCallback;

  /// Initialize the phone call service and listen for call events
  static void initialize({
    required Function(String phoneNumber, int? duration) onCallEnded,
    Function(String phoneNumber)? onCallAnswered,
    Function(String phoneNumber)? onCallStarted,
  }) {
    _onCallEndedCallback = onCallEnded;
    _onCallAnsweredCallback = onCallAnswered;
    _onCallStartedCallback = onCallStarted;
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
          final phoneNumber = event['phoneNumber'] as String? ?? '';
          print(
            'PhoneCallService: Event type: $eventType, Phone: $phoneNumber',
          );

          switch (eventType) {
            case 'callStarted':
              print('PhoneCallService: Call started for $phoneNumber');
              _onCallStartedCallback?.call(phoneNumber);
              break;

            case 'callRinging':
              print('PhoneCallService: Call ringing for $phoneNumber');
              break;

            case 'callAnswered':
              print('PhoneCallService: Call answered for $phoneNumber');
              _onCallAnsweredCallback?.call(phoneNumber);
              break;

            case 'callEnded':
              final durationValue = event['duration'] as int?;
              print(
                'PhoneCallService: Call ended - Phone: $phoneNumber, Duration: $durationValue',
              );
              // Duration is valid if >= 0
              final duration =
                  (durationValue != null && durationValue >= 0)
                      ? durationValue
                      : null;
              print(
                'PhoneCallService: Calling callback with phone: $phoneNumber, duration: $duration',
              );
              _onCallEndedCallback?.call(phoneNumber, duration);
              break;
          }
        }
      },
      onError: (error) {
        print('Error listening to call events: $error');
      },
    );
  }

  /// Make a phone call and start tracking
  static Future<bool> makeCall(String phoneNumber, {String? leadId}) async {
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
    _onCallAnsweredCallback = null;
    _onCallStartedCallback = null;
  }
}
