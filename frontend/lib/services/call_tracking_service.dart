import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Model for call data
class CallData {
  final String phoneNumber;
  final int duration; // in seconds
  final DateTime startTime;
  final DateTime endTime;
  final CallType callType;
  final CallState callState;

  CallData({
    required this.phoneNumber,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.callType,
    required this.callState,
  });

  @override
  String toString() {
    return 'CallData(phone: $phoneNumber, duration: ${duration}s, type: $callType, state: $callState)';
  }
}

enum CallType { incoming, outgoing }

enum CallState { ringing, answered, ended }

/// Comprehensive call tracking service for Android
class CallTrackingService extends ChangeNotifier {
  static final CallTrackingService _instance = CallTrackingService._internal();
  factory CallTrackingService() => _instance;
  CallTrackingService._internal();

  // Stream controllers
  final StreamController<CallData> _callDataController =
      StreamController<CallData>.broadcast();
  final StreamController<CallData> _callEndedController =
      StreamController<CallData>.broadcast();

  // Current call tracking
  String? _currentCallNumber;
  DateTime? _callStartTime;
  DateTime? _callAnswerTime;
  CallType? _currentCallType;
  bool _isCallActive = false;
  bool _isInitialized = false;

  // Streams
  Stream<CallData> get onCallData => _callDataController.stream;
  Stream<CallData> get onCallEnded => _callEndedController.stream;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isCallActive => _isCallActive;
  String? get currentCallNumber => _currentCallNumber;
  int get currentCallDuration {
    if (_callAnswerTime != null) {
      return DateTime.now().difference(_callAnswerTime!).inSeconds;
    }
    return 0;
  }

  /// Initialize call tracking service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Check if platform is Android
      if (!Platform.isAndroid) {
        print('CallTrackingService: Only Android is supported');
        return false;
      }

      // Request permissions
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        print('CallTrackingService: Required permissions not granted');
        return false;
      }

      // Initialize phone state monitoring
      await _initializePhoneStateMonitoring();

      _isInitialized = true;
      print('CallTrackingService: Successfully initialized');
      return true;
    } catch (e) {
      print('CallTrackingService: Error during initialization: $e');
      return false;
    }
  }

  /// Request required permissions
  Future<bool> _requestPermissions() async {
    try {
      final permissions = [Permission.phone, Permission.systemAlertWindow];

      // Request permissions
      Map<Permission, PermissionStatus> statuses = await permissions.request();

      // Check if all permissions are granted
      bool allGranted = true;
      for (var permission in permissions) {
        final status = statuses[permission] ?? PermissionStatus.denied;
        if (status != PermissionStatus.granted) {
          print(
            'CallTrackingService: Permission $permission not granted: $status',
          );
          allGranted = false;
        }
      }

      return allGranted;
    } catch (e) {
      print('CallTrackingService: Error requesting permissions: $e');
      return false;
    }
  }

  /// Initialize phone state monitoring via method channel
  Future<void> _initializePhoneStateMonitoring() async {
    try {
      const platform = MethodChannel('com.telecaller.app/call_tracking');

      // Listen to phone state changes from native code
      platform.setMethodCallHandler((call) async {
        print('CallTrackingService: Received method call: ${call.method}');
        switch (call.method) {
          case 'onCallStateChanged':
            final phoneNumber = call.arguments['phoneNumber'] as String?;
            final state = call.arguments['state'] as String?;
            _handlePhoneStateChangeFromNative(phoneNumber, state);
            return null;
          case 'onCallEnded':
            final phoneNumber = call.arguments['phoneNumber'] as String?;
            final duration = call.arguments['duration'] as int?;
            _handleCallEndedFromNative(phoneNumber, duration);
            return null;
          default:
            return null;
        }
      });

      print('CallTrackingService: Phone state monitoring initialized');
    } catch (e) {
      print(
        'CallTrackingService: Error initializing phone state monitoring: $e',
      );
      // Don't rethrow - allow app to continue without call tracking
    }
  }

  /// Handle phone state change from native code
  void _handlePhoneStateChangeFromNative(String? phoneNumber, String? state) {
    if (phoneNumber == null || state == null) return;

    print(
      'CallTrackingService: Phone state changed - Number: $phoneNumber, State: $state',
    );

    switch (state.toLowerCase()) {
      case 'ringing':
        _handleIncomingCall(phoneNumber);
        break;
      case 'offhook':
      case 'answered':
        _handleCallStarted(phoneNumber);
        break;
      case 'idle':
        _handleCallEnded();
        break;
    }
  }

  /// Handle call ended from native code
  void _handleCallEndedFromNative(String? phoneNumber, int? duration) {
    if (phoneNumber == null || duration == null) return;

    print(
      'CallTrackingService: Call ended from native - Number: $phoneNumber, Duration: ${duration}s',
    );

    if (duration > 0) {
      final endTime = DateTime.now();
      final startTime = endTime.subtract(Duration(seconds: duration));

      final callData = CallData(
        phoneNumber: phoneNumber,
        duration: duration,
        startTime: startTime,
        endTime: endTime,
        callType: _currentCallType ?? CallType.incoming,
        callState: CallState.ended,
      );

      _callEndedController.add(callData);
      _callDataController.add(callData);

      print('CallTrackingService: Emitted call ended event: $callData');
    }

    _isCallActive = false;
    _currentCallNumber = null;
    _callStartTime = null;
    _callAnswerTime = null;
    _currentCallType = null;

    notifyListeners();
  }

  /// Handle incoming call
  void _handleIncomingCall(String? phoneNumber) {
    print('CallTrackingService: Incoming call from: $phoneNumber');

    _currentCallNumber = phoneNumber ?? 'Unknown';
    _currentCallType = CallType.incoming;
    _callStartTime = DateTime.now();
    _callAnswerTime = null;
    _isCallActive = false;

    // Emit call data for ringing state
    final callData = CallData(
      phoneNumber: _currentCallNumber!,
      duration: 0,
      startTime: _callStartTime!,
      endTime: _callStartTime!,
      callType: _currentCallType!,
      callState: CallState.ringing,
    );

    _callDataController.add(callData);
    notifyListeners();
  }

  /// Handle call started (answered)
  void _handleCallStarted(String? phoneNumber) {
    print('CallTrackingService: Call started/answered: $phoneNumber');

    // If we don't have call info yet, this might be an outgoing call
    if (_currentCallNumber == null) {
      _currentCallNumber = phoneNumber ?? 'Unknown';
      _currentCallType = CallType.outgoing;
      _callStartTime = DateTime.now();
    }

    _callAnswerTime = DateTime.now();
    _isCallActive = true;

    // Emit call data for answered state
    final callData = CallData(
      phoneNumber: _currentCallNumber!,
      duration: 0,
      startTime: _callStartTime ?? _callAnswerTime!,
      endTime: _callAnswerTime!,
      callType: _currentCallType ?? CallType.outgoing,
      callState: CallState.answered,
    );

    _callDataController.add(callData);
    notifyListeners();
  }

  /// Handle call ended
  void _handleCallEnded() {
    print('CallTrackingService: Call ended');

    if (_currentCallNumber != null && _callAnswerTime != null) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_callAnswerTime!).inSeconds;

      print('CallTrackingService: Call duration: ${duration}s');

      final callData = CallData(
        phoneNumber: _currentCallNumber!,
        duration: duration,
        startTime: _callStartTime ?? _callAnswerTime!,
        endTime: endTime,
        callType: _currentCallType ?? CallType.incoming,
        callState: CallState.ended,
      );

      // Emit call ended event
      _callEndedController.add(callData);
      _callDataController.add(callData);

      print('CallTrackingService: Emitted call ended event: $callData');
    }

    _isCallActive = false;
    notifyListeners();
  }

  /// Get recent call logs (placeholder)
  Future<List<dynamic>> getRecentCallLogs({int limit = 10}) async {
    print('CallTrackingService: Call log access not available');
    return [];
  }

  /// Manually start call tracking (for outgoing calls)
  void startOutgoingCallTracking(String phoneNumber) {
    print(
      'CallTrackingService: Manually starting outgoing call tracking for: $phoneNumber',
    );

    _currentCallNumber = phoneNumber;
    _currentCallType = CallType.outgoing;
    _callStartTime = DateTime.now();
    _callAnswerTime = null;
    _isCallActive = false;

    final callData = CallData(
      phoneNumber: phoneNumber,
      duration: 0,
      startTime: _callStartTime!,
      endTime: _callStartTime!,
      callType: CallType.outgoing,
      callState: CallState.ringing,
    );

    _callDataController.add(callData);
    notifyListeners();
  }

  /// Retrieve cached call result from Android SharedPreferences
  Future<CallData?> checkForCachedCallResult(String phoneNumber) async {
    try {
      const platform = MethodChannel('com.telecaller.app/call_tracking');

      final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'getCachedCallResult',
        {'phoneNumber': phoneNumber},
      );

      if (result != null) {
        final phone = result['phoneNumber'] as String? ?? 'Unknown';
        final duration = result['duration'] as int? ?? 0;
        final timestamp = result['timestamp'] as int? ?? 0;
        final callType = result['callType'] as String? ?? 'incoming';

        print(
          'CallTrackingService: Retrieved cached call result: phone=$phone, duration=$duration',
        );

        final callData = CallData(
          phoneNumber: phone,
          duration: duration,
          startTime: DateTime.fromMillisecondsSinceEpoch(timestamp),
          endTime: DateTime.now(),
          callType:
              callType == 'outgoing' ? CallType.outgoing : CallType.incoming,
          callState: CallState.ended,
        );

        return callData;
      }

      print(
        'CallTrackingService: No cached call result found for: $phoneNumber',
      );
      return null;
    } catch (e) {
      print('CallTrackingService: Error retrieving cached call result: $e');
      return null;
    }
  }

  /// Check permissions status
  Future<Map<String, bool>> checkPermissions() async {
    return {
      'phone': await Permission.phone.isGranted,
      'systemAlertWindow': await Permission.systemAlertWindow.isGranted,
    };
  }

  /// Dispose resources
  @override
  void dispose() {
    _callDataController.close();
    _callEndedController.close();
    super.dispose();
  }
}
