import 'dart:async';
import 'package:flutter/material.dart';
import 'package:telecaller_app/services/call_tracking_service.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/lead_model.dart';

/// Controller for managing call tracking and integration with lead management
class CallTrackingController extends ChangeNotifier {
  final CallTrackingService _callTrackingService = CallTrackingService();
  final LeadRepository _leadRepository = LeadRepository();

  StreamSubscription<CallData>? _callDataSubscription;
  StreamSubscription<CallData>? _callEndedSubscription;

  // Current call state
  CallData? _currentCall;
  CallData? _lastEndedCall;
  bool _isInitialized = false;

  // Callbacks for UI integration
  Function(String phoneNumber, int duration)? onCallEnded;
  Function(CallData callData)? onCallStateChanged;

  // Getters
  bool get isInitialized => _isInitialized;
  CallData? get currentCall => _currentCall;
  CallData? get lastEndedCall => _lastEndedCall;
  bool get isCallActive => _callTrackingService.isCallActive;
  int get currentCallDuration => _callTrackingService.currentCallDuration;

  /// Initialize call tracking
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize call tracking service
      final success = await _callTrackingService.initialize();
      if (!success) {
        print(
          'CallTrackingController: Failed to initialize call tracking service',
        );
        return false;
      }

      // Subscribe to call events
      _subscribeToCallEvents();

      _isInitialized = true;
      print('CallTrackingController: Successfully initialized');
      return true;
    } catch (e) {
      print('CallTrackingController: Error during initialization: $e');
      return false;
    }
  }

  /// Subscribe to call tracking events
  void _subscribeToCallEvents() {
    // Listen to all call state changes
    _callDataSubscription = _callTrackingService.onCallData.listen(
      (callData) {
        print('CallTrackingController: Call state changed: $callData');
        _currentCall = callData;

        // Notify UI about call state change
        onCallStateChanged?.call(callData);
        notifyListeners();
      },
      onError: (error) {
        print('CallTrackingController: Call data stream error: $error');
      },
    );

    // Listen specifically to call ended events
    _callEndedSubscription = _callTrackingService.onCallEnded.listen(
      (callData) {
        print('CallTrackingController: Call ended: $callData');
        _handleCallEnded(callData);
      },
      onError: (error) {
        print('CallTrackingController: Call ended stream error: $error');
      },
    );
  }

  /// Handle call ended event
  void _handleCallEnded(CallData callData) {
    _lastEndedCall = callData;
    _currentCall = null;

    print(
      'CallTrackingController: Processing ended call - Phone: ${callData.phoneNumber}, Duration: ${callData.duration}s',
    );

    // Check if this call matches any existing lead
    _updateExistingLeadWithCallData(callData);

    // Notify UI callback
    onCallEnded?.call(callData.phoneNumber, callData.duration);

    notifyListeners();
  }

  /// Update existing lead with call data
  Future<void> _updateExistingLeadWithCallData(CallData callData) async {
    try {
      // Clean phone number for matching
      final cleanPhoneNumber = _cleanPhoneNumber(callData.phoneNumber);

      // Find existing lead with matching phone number
      final existingLead = _findLeadByPhoneNumber(cleanPhoneNumber);

      if (existingLead != null) {
        print(
          'CallTrackingController: Found existing lead for phone ${cleanPhoneNumber}: ${existingLead.name}',
        );

        // Update lead with call duration
        final updatedLead = LeadModel(
          id: existingLead.id,
          name: existingLead.name,
          phone: existingLead.phone,
          brand: existingLead.brand,
          location: existingLead.location,
          leadStatus: existingLead.leadStatus,
          callStatus: existingLead.callStatus,
          followUpDate: existingLead.followUpDate,
          reason: existingLead.reason,
          category: existingLead.category,
          callDuration: callData.duration, // Update call duration
          createdAt: existingLead.createdAt,
        );

        await _leadRepository.updateLead(updatedLead);
        print(
          'CallTrackingController: Updated existing lead with call duration: ${callData.duration}s',
        );
      } else {
        print(
          'CallTrackingController: No existing lead found for phone number: ${cleanPhoneNumber}',
        );
      }
    } catch (e) {
      print(
        'CallTrackingController: Error updating existing lead with call data: $e',
      );
    }
  }

  /// Find lead by phone number
  LeadModel? _findLeadByPhoneNumber(String phoneNumber) {
    try {
      final allLeads = _leadRepository.allLeads;

      for (final lead in allLeads) {
        final leadPhone = _cleanPhoneNumber(lead.phone);
        if (leadPhone == phoneNumber) {
          return lead;
        }
      }

      return null;
    } catch (e) {
      print('CallTrackingController: Error finding lead by phone number: $e');
      return null;
    }
  }

  /// Clean phone number for comparison
  String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Handle country codes - if number starts with 91 and is 12 digits, remove 91
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }

    // Handle +91 format
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = cleaned.substring(1);
    }

    return cleaned;
  }

  /// Start tracking outgoing call
  void startOutgoingCall(String phoneNumber) {
    print(
      'CallTrackingController: Starting outgoing call tracking for: $phoneNumber',
    );
    _callTrackingService.startOutgoingCallTracking(phoneNumber);
  }

  /// Get call data for phone number (for pre-filling forms)
  CallData? getCallDataForPhoneNumber(String phoneNumber) {
    final cleanNumber = _cleanPhoneNumber(phoneNumber);

    if (_lastEndedCall != null) {
      final lastCallCleanNumber = _cleanPhoneNumber(
        _lastEndedCall!.phoneNumber,
      );
      if (lastCallCleanNumber == cleanNumber) {
        return _lastEndedCall;
      }
    }

    return null;
  }

  /// Check if phone number matches current/recent call
  bool isPhoneNumberFromRecentCall(String phoneNumber) {
    final cleanNumber = _cleanPhoneNumber(phoneNumber);

    // Check current call
    if (_currentCall != null) {
      final currentCallCleanNumber = _cleanPhoneNumber(
        _currentCall!.phoneNumber,
      );
      if (currentCallCleanNumber == cleanNumber) {
        return true;
      }
    }

    // Check last ended call
    if (_lastEndedCall != null) {
      final lastCallCleanNumber = _cleanPhoneNumber(
        _lastEndedCall!.phoneNumber,
      );
      if (lastCallCleanNumber == cleanNumber) {
        return true;
      }
    }

    return false;
  }

  /// Get recent call logs
  Future<List<dynamic>> getRecentCallLogs({int limit = 10}) async {
    return await _callTrackingService.getRecentCallLogs(limit: limit);
  }

  /// Check permissions
  Future<Map<String, bool>> checkPermissions() async {
    return await _callTrackingService.checkPermissions();
  }

  /// Request permissions
  Future<bool> requestPermissions() async {
    return await _callTrackingService.initialize();
  }

  /// Set callback for call ended events
  void setOnCallEndedCallback(
    Function(String phoneNumber, int duration) callback,
  ) {
    onCallEnded = callback;
  }

  /// Set callback for call state changes
  void setOnCallStateChangedCallback(Function(CallData callData) callback) {
    onCallStateChanged = callback;
  }

  /// Clear callbacks
  void clearCallbacks() {
    onCallEnded = null;
    onCallStateChanged = null;
  }

  @override
  void dispose() {
    _callDataSubscription?.cancel();
    _callEndedSubscription?.cancel();
    clearCallbacks();
    super.dispose();
  }
}
