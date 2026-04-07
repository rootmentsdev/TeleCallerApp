import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/services/incoming_call_handler.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/main.dart';

class CallTrackingController extends ChangeNotifier {
  final LeadRepository _leadRepository = LeadRepository();
  static const MethodChannel _methodChannel = MethodChannel(
    'com.telecaller.app/call_tracking',
  );

  String? _lastPhone;
  int? _lastDuration;
  bool _isInitialized = false;
  bool _lastCallWasAnswered = false; // Track if the last call was answered
  bool _lastCallWasIncoming = false; // Track if the last call was incoming
  bool _outgoingCallInProgress =
      false; // Track if an outgoing call is currently in progress

  bool get isInitialized => _isInitialized;
  String? get lastPhone => _lastPhone;
  int? get lastDuration => _lastDuration;
  bool get lastCallWasAnswered => _lastCallWasAnswered;
  bool get lastCallWasIncoming => _lastCallWasIncoming;
  bool get outgoingCallInProgress => _outgoingCallInProgress;

  get lastEndedCall => null;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Listen to PhoneCallService (EVENT channel for outgoing calls)
    PhoneCallService.initialize((phone, duration) {
      print(
        'CallTrackingController: Received duration=$duration for phone=$phone (outgoing call)',
      );
      _lastPhone = phone;

      // CRITICAL: Use the actual duration from Android call log
      // Android already provides the correct answered duration
      // Do NOT recalculate - just use it directly
      if (_lastCallWasAnswered && duration > 0) {
        _lastDuration = duration;
        print(
          'CallTrackingController: Outgoing call was answered - using duration=$_lastDuration seconds from Android call log',
        );
      } else {
        _lastDuration = 0;
        print(
          'CallTrackingController: Outgoing call was NOT answered - duration set to 0',
        );
      }

      _lastCallWasIncoming = false; // Outgoing call
      _updateLeadWithDuration(phone, _lastDuration ?? 0);

      // Only notify if controller is not disposed
      if (!_disposed) {
        notifyListeners();
      }
    });

    // Listen to CallTrackingReceiver (METHOD channel for incoming calls)
    _methodChannel.setMethodCallHandler((call) async {
      print('CallTrackingController: Method channel received: ${call.method}');

      if (call.method == 'onCallEnded') {
        final phoneNumber = call.arguments['phoneNumber'] as String? ?? '';
        final duration = call.arguments['duration'] as int? ?? 0;
        final callType = call.arguments['callType'] as String? ?? 'incoming';

        print(
          'CallTrackingController: Received onCallEnded - phone=$phoneNumber, duration=$duration, callType=$callType, _outgoingCallInProgress=$_outgoingCallInProgress',
        );

        _lastPhone = phoneNumber;

        // CRITICAL: Use the actual duration from Android call log
        // Android already provides the correct answered duration (from answer to end)
        // Do NOT recalculate - just use it directly
        if (_lastCallWasAnswered && duration > 0) {
          _lastDuration = duration;
          print(
            'CallTrackingController: Call was answered - using duration=$_lastDuration seconds from Android call log',
          );
        } else {
          // Call was not answered, set duration to 0
          _lastDuration = 0;
          print(
            'CallTrackingController: Call was NOT answered - duration set to 0',
          );
        }

        // CRITICAL: Set _lastCallWasIncoming based on callType from Android
        // This ensures we only show incoming call form for actual incoming calls
        _lastCallWasIncoming = (callType == 'incoming');
        print(
          'CallTrackingController: Set _lastCallWasIncoming=$_lastCallWasIncoming based on callType=$callType',
        );

        // Reset outgoing call flag when call ends
        _outgoingCallInProgress = false;
        print('CallTrackingController: Reset _outgoingCallInProgress=false');

        _updateLeadWithDuration(phoneNumber, _lastDuration ?? 0);

        // Notify listeners BEFORE resetting answered flag so UI can update
        print('CallTrackingController: Notifying listeners...');
        if (!_disposed) {
          notifyListeners();
          print('CallTrackingController: Listeners notified');
        }

        // Reset answered flag AFTER notifying listeners
        _lastCallWasAnswered = false;

        // Show add lead bottom sheet for both incoming AND outgoing calls with duration > 0
        if ((_lastDuration ?? 0) > 0 &&
            phoneNumber != 'Unknown' &&
            phoneNumber.isNotEmpty) {
          print(
            'CallTrackingController: Call completed with duration=$_lastDuration for phone=$phoneNumber, isIncoming=$_lastCallWasIncoming',
          );

          // Only show popup for incoming calls
          // For outgoing calls, the user is already on the outgoing call detail screen
          if (_lastCallWasIncoming) {
            print(
              'CallTrackingController: Showing incoming call form for phone=$phoneNumber, duration=$_lastDuration',
            );
            _showAddLeadBottomSheetForIncomingCall(
              phoneNumber,
              _lastDuration ?? 0,
            );
          } else {
            print(
              'CallTrackingController: Outgoing call completed - user is already on outgoing call detail screen, not showing popup',
            );
          }
        } else {
          print(
            'CallTrackingController: NOT showing form - duration=$_lastDuration, phone=$phoneNumber',
          );
        }
      } else if (call.method == 'onCallStateChanged') {
        final state = call.arguments['state'] as String? ?? '';
        final phoneNumber = call.arguments['phoneNumber'] as String? ?? '';

        print(
          'CallTrackingController: Received onCallStateChanged - state=$state, phone=$phoneNumber',
        );

        // Track if call was answered
        if (state == 'answered') {
          _lastCallWasAnswered = true;
          print('CallTrackingController: Call was answered');
        }

        // Track if call is incoming (ringing state without outgoing flag)
        if (state == 'ringing') {
          _lastCallWasIncoming = true;
          print('CallTrackingController: Incoming call detected');
        }
      }
    });

    _isInitialized = true;
    return true;
  }

  void startOutgoingCall(String phone) {
    _lastCallWasAnswered = false; // Reset answered flag when new call starts
    _lastCallWasIncoming = false; // Mark as outgoing call
    _outgoingCallInProgress = true; // Mark that outgoing call is in progress
    print(
      'CallTrackingController: Starting outgoing call - _outgoingCallInProgress=true',
    );
    PhoneCallService.makeCall(phone);
  }

  /// Show correct popup for incoming calls by checking phone via API
  void _showAddLeadBottomSheetForIncomingCall(
    String phoneNumber,
    int duration,
  ) {
    final cleanPhone = _cleanPhoneNumber(phoneNumber);

    print('╔══════════════════════════════════════════════════════════╗');
    print('║      _showAddLeadBottomSheetForIncomingCall()            ║');
    print('╠══════════════════════════════════════════════════════════╣');
    print('║  rawPhone   : $phoneNumber');
    print('║  cleanPhone : $cleanPhone');
    print('║  duration   : $duration');
    print('╚══════════════════════════════════════════════════════════╝');

    final context = navigatorKey.currentContext;
    print(
      'CallTrackingController: navigatorKey.currentContext is ${context == null ? "NULL — cannot show popup" : "available"}',
    );

    if (context == null) {
      print('CallTrackingController: No context available to show popup');
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      final currentContext = navigatorKey.currentContext;
      print(
        'CallTrackingController: After delay — currentContext is ${currentContext == null ? "NULL" : "available"}, mounted=$mounted',
      );
      if (currentContext != null && mounted) {
        print(
          'CallTrackingController: Calling IncomingCallHandler.handleIncomingCall for phone=$cleanPhone, duration=$duration',
        );
        IncomingCallHandler().handleIncomingCall(
          context: currentContext,
          phoneNumber: cleanPhone,
          callDuration: duration,
        );
      }
    });
  }

  bool get mounted => !_disposed;

  void _updateLeadWithDuration(String phone, int duration) {
    final cleanPhone = _cleanPhoneNumber(phone);
    final lead = _findLeadByPhone(cleanPhone);

    // CRITICAL: Only update if duration > 0 (call was answered)
    if (lead != null && duration > 0) {
      // Increment call count for each successful answered call
      final newCallCount = lead.callCount + 1;
      print(
        'CallTrackingController: Updating lead $cleanPhone with duration=$duration, callCount=$newCallCount',
      );
      final updatedLead = LeadModel(
        id: lead.id,
        name: lead.name,
        phone: lead.phone,
        brand: lead.brand,
        location: lead.location,
        leadStatus: lead.leadStatus,
        callStatus: lead.callStatus,
        followUpDate: lead.followUpDate,
        reason: lead.reason,
        category: lead.category,
        callDuration: duration,
        callCount: newCallCount, // Increment call count
        createdAt: lead.createdAt,
      );
      _leadRepository.updateLead(updatedLead);
    } else if (duration == 0) {
      print(
        'CallTrackingController: NOT updating lead - call was not answered (duration=0)',
      );
    }
  }

  LeadModel? _findLeadByPhone(String phone) {
    return _leadRepository.allLeads.cast<LeadModel?>().firstWhere(
      (lead) => lead != null && _cleanPhoneNumber(lead.phone) == phone,
      orElse: () => null,
    );
  }

  String _cleanPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
