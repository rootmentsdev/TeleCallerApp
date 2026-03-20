import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/services/phone_identification_service.dart';
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
      _lastDuration = duration;
      _lastCallWasIncoming = false; // Outgoing call
      _updateLeadWithDuration(phone, duration);

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
        _lastDuration = duration;

        // CRITICAL: Set _lastCallWasIncoming based on callType from Android
        // This ensures we only show incoming call form for actual incoming calls
        _lastCallWasIncoming = (callType == 'incoming');
        print(
          'CallTrackingController: Set _lastCallWasIncoming=$_lastCallWasIncoming based on callType=$callType',
        );

        // Reset outgoing call flag when call ends
        _outgoingCallInProgress = false;
        print('CallTrackingController: Reset _outgoingCallInProgress=false');

        // Reset answered flag when call ends
        if (duration > 0) {
          // Call was answered and had duration
          _lastCallWasAnswered = true;
        } else {
          // Reset answered flag - call ended without duration
          _lastCallWasAnswered = false;
        }

        _updateLeadWithDuration(phoneNumber, duration);

        // Show add lead bottom sheet ONLY for incoming calls with duration > 0
        // Do NOT show for outgoing calls - they are handled by the outgoing call form
        if (_lastCallWasIncoming &&
            duration > 0 &&
            phoneNumber != 'Unknown' &&
            phoneNumber.isNotEmpty) {
          print(
            'CallTrackingController: Showing incoming call form for phone=$phoneNumber, duration=$duration',
          );
          _showAddLeadBottomSheetForIncomingCall(phoneNumber, duration);
        } else {
          print(
            'CallTrackingController: NOT showing incoming call form - isIncoming=$_lastCallWasIncoming, duration=$duration, phone=$phoneNumber',
          );
        }

        print('CallTrackingController: Notifying listeners...');
        // Only notify if controller is not disposed
        if (!_disposed) {
          notifyListeners();
          print('CallTrackingController: Listeners notified');
        } else {
          print(
            'CallTrackingController: Controller is disposed, not notifying',
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
          'CallTrackingController: Calling PhoneIdentificationService.identify for phone=$cleanPhone, duration=$duration',
        );
        PhoneIdentificationService().identify(
          context: currentContext,
          phone: cleanPhone,
          callDuration: duration,
        );
      }
    });
  }

  bool get mounted => !_disposed;

  void _updateLeadWithDuration(String phone, int duration) {
    final cleanPhone = _cleanPhoneNumber(phone);
    final lead = _findLeadByPhone(cleanPhone);

    if (lead != null && duration > 0) {
      // Increment call count for each successful call
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
