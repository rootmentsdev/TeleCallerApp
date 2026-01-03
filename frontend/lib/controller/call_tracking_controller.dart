import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/lead_model.dart';

class CallTrackingController extends ChangeNotifier {
  final LeadRepository _leadRepository = LeadRepository();
  static const MethodChannel _methodChannel = MethodChannel(
    'com.telecaller.app/call_tracking',
  );

  String? _lastPhone;
  int? _lastDuration;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  String? get lastPhone => _lastPhone;
  int? get lastDuration => _lastDuration;

  get lastEndedCall => null;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Listen to PhoneCallService (EVENT channel for outgoing calls)
    PhoneCallService.initialize((phone, duration) {
      print(
        'CallTrackingController: Received duration=$duration for phone=$phone',
      );
      _lastPhone = phone;
      _lastDuration = duration;
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

        print(
          'CallTrackingController: Received onCallEnded - phone=$phoneNumber, duration=$duration',
        );

        _lastPhone = phoneNumber;
        _lastDuration = duration;
        _updateLeadWithDuration(phoneNumber, duration);

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
      }
    });

    _isInitialized = true;
    return true;
  }

  void startOutgoingCall(String phone) {
    PhoneCallService.makeCall(phone);
  }

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
