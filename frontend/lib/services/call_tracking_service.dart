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
  final String sessionId; // Unique session identifier
  final bool cancelled; // Whether call was cancelled (early IDLE)
  final String durationSource; // "timestamp", "calllog", or "none"

  CallData({
    required this.phoneNumber,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.callType,
    required this.callState,
    required this.sessionId,
    this.cancelled = false,
    this.durationSource = "none",
  });

  @override
  String toString() {
    return 'CallData(phone: $phoneNumber, duration: ${duration}s, type: $callType, state: $callState, session: $sessionId, cancelled: $cancelled, source: $durationSource)';
  }
}

enum CallType { incoming, outgoing }

enum CallState { ringing, answered, ended }

/// Strict call state machine states
enum CallStateMachine {
  idle, // Initial state - no call
  dialing, // Call Now clicked, dialing
  ringing, // Phone ringing
  connected, // OFFHOOK - call answered
  ended, // IDLE after OFFHOOK - call ended
}

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

  // Strict state machine
  CallStateMachine _callState = CallStateMachine.idle;
  bool _offhookOccurred = false; // Track if OFFHOOK has occurred
  bool _callEndProcessed = false; // Track if call end has been processed

  // Streams
  Stream<CallData> get onCallData => _callDataController.stream;
  Stream<CallData> get onCallEnded => _callEndedController.stream;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isCallActive => _isCallActive;
  String? get currentCallNumber => _currentCallNumber;
  CallStateMachine get callState => _callState;
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
            final sessionId = call.arguments['sessionId'] as String?;
            _handlePhoneStateChangeFromNative(phoneNumber, state, sessionId);
            return null;
          case 'onCallEnded':
            final phoneNumber = call.arguments['phoneNumber'] as String?;
            final duration = call.arguments['duration'] as int?;
            final sessionId = call.arguments['sessionId'] as String?;
            final cancelled = call.arguments['cancelled'] as bool? ?? false;
            final durationSource = call.arguments['durationSource'] as String?;

            // 🔒 HARD BLOCK: Only block if duration is null (completely invalid)
            // Allow all other cases including duration==0 so we can compute from timestamps
            if (duration == null) {
              print(
                '⛔ BLOCKED onCallEnded(duration==null) at channel entry point',
              );
              return null;
            }

            _handleCallEndedFromNative(
              phoneNumber,
              duration,
              sessionId,
              cancelled,
              durationSource,
            );
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
  void _handlePhoneStateChangeFromNative(
    String? phoneNumber,
    String? state,
    String? sessionId,
  ) async {
    if (state == null) return;
    // Allow null phone numbers; prefer most recently seen phone for finalization
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      _currentCallNumber = phoneNumber;
    }

    print(
      'CallTrackingService: Phone state changed - Number: ${phoneNumber ?? _currentCallNumber ?? 'Unknown'}, State: $state, Session: $sessionId',
    );

    switch (state.toLowerCase()) {
      case 'ringing':
        _handleIncomingCall(phoneNumber, sessionId);
        break;
      case 'offhook':
      case 'answered':
        _handleCallStarted(phoneNumber, sessionId);
        break;
      case 'idle':
        // Some devices/platforms don't emit a timestamp-based onCallEnded event.
        // When we see IDLE after an OFFHOOK (i.e., call was active), wait briefly
        // to allow the system to write call log entries, then check cached results
        // (with retries) and fall back to timestamp calculation if needed.
        print(
          'CallTrackingService: IDLE state received - _offhookOccurred=$_offhookOccurred, _callState=$_callState, _callEndProcessed=$_callEndProcessed',
        );

        // Always try to finalize if we had an OFFHOOK and haven't finalized yet
        if (_offhookOccurred && !_callEndProcessed) {
          // Small delay so native call log/cached result has time to be written
          const waitMs = 600;
          print(
            'CallTrackingService: IDLE detected - waiting ${waitMs}ms before checking call log/cached result',
          );
          await Future.delayed(Duration(milliseconds: waitMs));

          final endTime = DateTime.now();
          final startTime = _callAnswerTime ?? _callStartTime ?? endTime;

          final phoneToUse = phoneNumber ?? _currentCallNumber ?? 'Unknown';

          try {
            // Try cached lookup for original phone and normalized variants
            final cached = await _findCachedCallResultForVariants(phoneToUse);
            if (cached != null && cached.duration > 0) {
              // Use cached call result as final
              print(
                'CallTrackingService: ✅ Using cached call result as FINAL for $phoneToUse (resolved phone=${cached.phoneNumber}): duration=${cached.duration}s',
              );

              _callEndProcessed = true;
              _callState = CallStateMachine.ended;

              _callEndedController.add(cached);
              _callDataController.add(cached);

              _resetCallState();
              notifyListeners();
              break; // exit case
            } else {
              print(
                'CallTrackingService: No cached result found for $phoneToUse (after trying variants)',
              );
            }
          } catch (e) {
            print(
              'CallTrackingService: Error while checking cached call result: $e',
            );
          }

          int calculatedDuration = 0;
          if (_callAnswerTime != null) {
            calculatedDuration = endTime.difference(_callAnswerTime!).inSeconds;
            print(
              'CallTrackingService: 📊 Calculated duration from OFFHOOK→IDLE: ${calculatedDuration}s',
            );
          } else if (_callStartTime != null) {
            calculatedDuration = endTime.difference(_callStartTime!).inSeconds;
            print(
              'CallTrackingService: 📊 Calculated duration from DIALING→IDLE: ${calculatedDuration}s',
            );
          }

          if (calculatedDuration > 0) {
            // Emit a FINAL timestamp-based end when we have reliable timestamps
            print(
              'CallTrackingService: Detected IDLE after OFFHOOK - emitting FINAL END (timestamp) using last known phone: $phoneToUse',
            );

            final callData = CallData(
              phoneNumber: phoneToUse,
              duration: calculatedDuration,
              startTime: startTime,
              endTime: endTime,
              callType: _currentCallType ?? CallType.incoming,
              callState: CallState.ended,
              sessionId: '',
              durationSource: 'timestamp',
            );

            _callEndProcessed = true;
            _callState = CallStateMachine.ended;

            _callEndedController.add(callData);
            _callDataController.add(callData);

            print(
              'CallTrackingService: ✅ FINAL call ended event emitted (source=timestamp, fallback-from-idle): $callData',
            );

            _resetCallState();
            notifyListeners();
          } else {
            // Fallback to provisional zero-duration so UI can poll cache
            print(
              'CallTrackingService: Detected IDLE after OFFHOOK but duration==0 - emitting provisional END (duration=0) to prompt UI polling',
            );

            final callData = CallData(
              phoneNumber: phoneToUse,
              duration: 0,
              startTime: startTime,
              endTime: endTime,
              callType: _currentCallType ?? CallType.incoming,
              callState: CallState.ended,
              sessionId: '',
              durationSource: 'none',
            );

            _callDataController.add(callData);
            // Do not reset internal state here - wait for authoritative onCallEnded
            notifyListeners();
          }
        }
        break;
    }
  }

  /// Handle call ended from native code
  void _handleCallEndedFromNative(
    String? phoneNumber,
    int? duration,
    String? sessionId,
    bool? cancelled,
    String? durationSource,
  ) {
    print(
      'CallTrackingService: Call ended from native - Phone: $phoneNumber, Duration: ${duration}s, Session: $sessionId, Source: $durationSource',
    );

    // ✅ ONLY TIMESTAMP END is FINAL AUTHORITY
    // Accept timestamp-based END even if phone is null or duration is 0
    if (durationSource == "timestamp") {
      print(
        'CallTrackingService: ✅ TIMESTAMP-based END - FINAL (phone may be null)',
      );

      // Mark call as ended to prevent duplicate processing
      _callEndProcessed = true;

      // Transition to ENDED state
      _callState = CallStateMachine.ended;

      // RULE: Duration = IDLE_time − OFFHOOK_time (timestamp only)
      final endTime = DateTime.now();
      final startTime =
          _callAnswerTime ??
          _callStartTime ??
          endTime.subtract(Duration(seconds: duration ?? 0));

      // Calculate duration from timestamps
      int calculatedDuration = 0;
      if (_callAnswerTime != null) {
        // Call was answered - calculate from OFFHOOK to IDLE
        calculatedDuration = endTime.difference(_callAnswerTime!).inSeconds;
        print(
          'CallTrackingService: 📊 Duration calculated from OFFHOOK→IDLE: ${calculatedDuration}s',
        );
      } else if (_callStartTime != null) {
        // Call was not answered - calculate from DIALING to IDLE
        calculatedDuration = endTime.difference(_callStartTime!).inSeconds;
        print(
          'CallTrackingService: 📊 Duration calculated from DIALING→IDLE: ${calculatedDuration}s',
        );
      } else {
        // Fallback to provided duration
        calculatedDuration = duration ?? 0;
        print(
          'CallTrackingService: 📊 Using provided duration: ${calculatedDuration}s',
        );
      }

      final callData = CallData(
        phoneNumber: phoneNumber ?? _currentCallNumber ?? 'Unknown',
        duration: calculatedDuration,
        startTime: startTime,
        endTime: endTime,
        callType: _currentCallType ?? CallType.incoming,
        callState: CallState.ended,
        sessionId: sessionId ?? '',
        cancelled: false,
        durationSource: "timestamp",
      );

      // Emit FINAL call ended event - this is the single source of truth
      _callEndedController.add(callData);
      _callDataController.add(callData);

      print(
        'CallTrackingService: ✅ FINAL call ended event emitted (source=timestamp): $callData',
      );

      // Reset state after emitting final event
      _resetCallState();
      notifyListeners();
      return;
    }

    // ⛔ Skip if duration is 0 and source is not timestamp
    // This prevents early/incomplete events from being processed
    if (duration == null || duration == 0) {
      print(
        'CallTrackingService: ⛔ SKIPPING - Invalid duration (duration=$duration, source=$durationSource)',
      );
      return;
    }

    // ✅ Accept call-log based durations as final when available and OFFHOOK was observed
    // This covers devices where timestamp-based END is not provided but call log duration is available.
    if (duration > 0 && _offhookOccurred) {
      final callData = CallData(
        phoneNumber: phoneNumber ?? _currentCallNumber ?? 'Unknown',
        duration: duration,
        startTime:
            _callAnswerTime ??
            _callStartTime ??
            DateTime.now().subtract(Duration(seconds: duration)),
        endTime: DateTime.now(),
        callType: _currentCallType ?? CallType.incoming,
        callState: CallState.ended,
        sessionId: sessionId ?? '',
        cancelled: cancelled ?? false,
        durationSource: durationSource ?? 'calllog',
      );

      // Mark call as ended to prevent duplicate processing
      _callEndProcessed = true;
      _callState = CallStateMachine.ended;

      _callEndedController.add(callData);
      _callDataController.add(callData);

      print(
        'CallTrackingService: ✅ call-log-based END accepted and emitted (source=${durationSource ?? 'calllog'}): $callData',
      );

      // Reset state and notify listeners
      _resetCallState();
      notifyListeners();
      return;
    }

    // ❌ All other END sources are ignored
    print(
      'CallTrackingService: ⛔ SKIPPING - Non-timestamp END (source=$durationSource)',
    );
  }

  /// Reset call state to IDLE
  void _resetCallState() {
    _callState = CallStateMachine.idle;
    _isCallActive = false;
    _currentCallNumber = null;
    _callStartTime = null;
    _callAnswerTime = null;
    _currentCallType = null;
    _offhookOccurred = false;
    _callEndProcessed = false;
    print('CallTrackingService: Call state reset to IDLE');
  }

  /// Public method to force reset state when navigating to new lead
  /// This ensures the singleton service doesn't carry over state from previous lead
  void forceResetState() {
    print('CallTrackingService: 🔄 Force reset state (navigating to new lead)');
    _resetCallState();
    notifyListeners();
  }

  /// Handle incoming call
  void _handleIncomingCall(String? phoneNumber, String? sessionId) {
    print(
      'CallTrackingService: 📞 RINGING - Incoming call from: $phoneNumber, Session: $sessionId',
    );

    _currentCallNumber = phoneNumber ?? 'Unknown';
    _currentCallType = CallType.incoming;
    _callStartTime = DateTime.now();
    _callAnswerTime = null;
    _isCallActive = false;
    _offhookOccurred = false; // Reset OFFHOOK flag
    _callEndProcessed = false; // Reset end flag

    // Transition to RINGING state
    _callState = CallStateMachine.ringing;

    // Emit call data for ringing state
    final callData = CallData(
      phoneNumber: _currentCallNumber!,
      duration: 0,
      startTime: _callStartTime!,
      endTime: _callStartTime!,
      callType: _currentCallType!,
      callState: CallState.ringing,
      sessionId: sessionId ?? '',
      durationSource: "none",
    );

    _callDataController.add(callData);
    notifyListeners();
  }

  /// Handle call started (answered) - OFFHOOK event
  Future<void> _handleCallStarted(
    String? phoneNumber,
    String? sessionId,
  ) async {
    // RULE: OFFHOOK sets callStartTime (once only)
    // Ignore duplicate OFFHOOK events
    if (_offhookOccurred) {
      print(
        'CallTrackingService: ⚠️ OFFHOOK - Duplicate OFFHOOK event (ignoring), Session: $sessionId',
      );
      return;
    }

    // STEP 4: Guard second call - if previous call ended, reset flags for new call
    if (_callEndProcessed && _callState == CallStateMachine.ended) {
      print(
        'CallTrackingService: 🔄 New OFFHOOK after previous call ended - resetting state for new call, Session: $sessionId',
      );
      _callEndProcessed = false;
      _callState = CallStateMachine.idle;
    }

    print(
      'CallTrackingService: ✅ OFFHOOK - Call answered: $phoneNumber, Session: $sessionId',
    );

    // Mark OFFHOOK as occurred (once only)
    _offhookOccurred = true;

    // If we don't have call info yet, this might be an outgoing call
    if (_currentCallNumber == null) {
      _currentCallNumber = phoneNumber ?? 'Unknown';
      _currentCallType = CallType.outgoing;
      _callStartTime = DateTime.now();
    }

    _callAnswerTime = DateTime.now();
    _isCallActive = true;

    // Transition to CONNECTED state
    _callState = CallStateMachine.connected;

    // Emit call data for answered state
    final callData = CallData(
      phoneNumber: _currentCallNumber!,
      duration: 0,
      startTime: _callStartTime ?? _callAnswerTime!,
      endTime: _callAnswerTime!,
      callType: _currentCallType ?? CallType.outgoing,
      callState: CallState.answered,
      sessionId: sessionId ?? '',
      durationSource: "none",
    );

    _callDataController.add(callData);
    notifyListeners();
  }

  /// Get recent call logs (placeholder)
  Future<List<dynamic>> getRecentCallLogs({int limit = 10}) async {
    print('CallTrackingService: Call log access not available');
    return [];
  }

  /// Try fetching cached call result using normalized phone variants.
  /// Returns the first non-null cached CallData (duration>0) or null.
  Future<CallData?> _findCachedCallResultForVariants(String phone) async {
    try {
      final tried = <String>{};

      String normalize(String s) => s.replaceAll(RegExp(r'\D'), '');

      final orig = phone;
      final digits = normalize(phone);
      final last10 =
          digits.length > 10 ? digits.substring(digits.length - 10) : digits;

      final candidates =
          [orig, digits, last10].where((p) => p.isNotEmpty).toList();

      for (final candidate in candidates) {
        if (tried.contains(candidate)) continue;
        tried.add(candidate);
        try {
          print(
            'CallTrackingService: Trying cached lookup for phone variant: $candidate',
          );
          final res = await checkForCachedCallResult(candidate);
          if (res != null && res.duration > 0) {
            print(
              'CallTrackingService: Cached lookup succeeded for variant $candidate -> duration=${res.duration}s',
            );
            return res;
          }
        } catch (e) {
          print(
            'CallTrackingService: Error fetching cached result for $candidate: $e',
          );
        }
      }

      return null;
    } catch (e) {
      print('CallTrackingService: _findCachedCallResultForVariants error: $e');
      return null;
    }
  }

  /// Manually start call tracking (for outgoing calls)
  void startOutgoingCallTracking(String phoneNumber) {
    // STEP 5: Guard second call - prevent starting if previous call not cleaned
    if (_callState != CallStateMachine.idle) {
      print(
        '⛔ Cannot start new call, previous not cleaned (state=$_callState)',
      );
      return;
    }

    print(
      'CallTrackingService: 📱 DIALING - Call Now clicked for: $phoneNumber',
    );

    _currentCallNumber = phoneNumber;
    _currentCallType = CallType.outgoing;
    _callStartTime = DateTime.now();
    _callAnswerTime = null;
    _isCallActive = false;
    _offhookOccurred = false; // Reset OFFHOOK flag
    _callEndProcessed = false; // Reset end flag

    // Transition to DIALING state
    _callState = CallStateMachine.dialing;

    final callData = CallData(
      phoneNumber: phoneNumber,
      duration: 0,
      startTime: _callStartTime!,
      endTime: _callStartTime!,
      callType: CallType.outgoing,
      callState: CallState.ringing,
      sessionId: '', // No session ID for manual outgoing call tracking
      durationSource: "none",
    );

    _callDataController.add(callData);
    notifyListeners();
  }

  /// Retrieve cached call result from Android SharedPreferences
  /// Will retry up to 3 times (500ms delay) to account for native write delays.
  Future<CallData?> checkForCachedCallResult(String phoneNumber) async {
    try {
      // Ensure phone permission is granted (READ_CALL_LOG required on Android)
      if (!await Permission.phone.isGranted) {
        print(
          'CallTrackingService: Permission PHONE (needed for call log) not granted',
        );
        return null;
      }

      const platform = MethodChannel('com.telecaller.app/call_tracking');

      const int maxAttempts = 3;
      const int delayMs = 500;

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          print(
            'CallTrackingService: Attempt $attempt to get cached call result for: $phoneNumber',
          );

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
              'CallTrackingService: Retrieved cached call result: phone=$phone, duration=$duration (attempt $attempt)',
            );

            if (duration > 0) {
              final callData = CallData(
                phoneNumber: phone,
                duration: duration,
                startTime: DateTime.fromMillisecondsSinceEpoch(timestamp),
                endTime: DateTime.now(),
                callType:
                    callType == 'outgoing'
                        ? CallType.outgoing
                        : CallType.incoming,
                callState: CallState.ended,
                sessionId: '', // No session ID for cached result
                durationSource: "calllog",
              );

              return callData;
            }
          }

          if (attempt < maxAttempts) {
            await Future.delayed(Duration(milliseconds: delayMs));
          }
        } catch (e) {
          print(
            'CallTrackingService: Error on attempt $attempt fetching cached result: $e',
          );
          if (attempt < maxAttempts)
            await Future.delayed(Duration(milliseconds: delayMs));
        }
      }

      print(
        'CallTrackingService: No cached call result found after retries for: $phoneNumber',
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
