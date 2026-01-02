import 'package:flutter/material.dart';
import 'package:telecaller_app/services/call_tracking_service.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/format_helper.dart';

/// Widget to display real-time call duration using StreamBuilder
/// Listens to onCallData stream for live updates during active calls
class CallDurationDisplay extends StatelessWidget {
  final String phoneNumber;
  final CallTrackingService callTrackingService;

  const CallDurationDisplay({
    super.key,
    required this.phoneNumber,
    required this.callTrackingService,
  });

  /// Check if phone numbers match (handles different formats)
  bool _isPhoneNumberMatch(String phone1, String phone2) {
    // Clean both numbers
    String clean1 = phone1.replaceAll(RegExp(r'[^\d]'), '');
    String clean2 = phone2.replaceAll(RegExp(r'[^\d]'), '');

    // Handle country codes
    if (clean1.startsWith('91') && clean1.length == 12) {
      clean1 = clean1.substring(2);
    }
    if (clean2.startsWith('91') && clean2.length == 12) {
      clean2 = clean2.substring(2);
    }

    // Handle leading zeros
    if (clean1.startsWith('0') && clean1.length == 11) {
      clean1 = clean1.substring(1);
    }
    if (clean2.startsWith('0') && clean2.length == 11) {
      clean2 = clean2.substring(1);
    }

    return clean1 == clean2 ||
        clean1.contains(clean2) ||
        clean2.contains(clean1);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CallData>(
      stream: callTrackingService.onCallData,
      builder: (context, snapshot) {
        // Check if we have data and it matches our phone number
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final callData = snapshot.data!;

        // Only show if phone number matches
        if (!_isPhoneNumberMatch(callData.phoneNumber, phoneNumber)) {
          return const SizedBox.shrink();
        }

        // Only show during active calls (ringing or answered)
        if (callData.callState == CallState.ended) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[300]!, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_in_talk,
                  size: 24,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCallStateText(callData.callState),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontFamily: TextConstant.dmSansRegular,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      callData.callState == CallState.answered
                          ? FormatHelper.formatCallDurationWithUnits(
                            callData.duration,
                          )
                          : 'Ringing...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getCallStateText(CallState state) {
    switch (state) {
      case CallState.ringing:
        return 'Call Ringing...';
      case CallState.answered:
        return 'Call Duration';
      case CallState.ended:
        return 'Call Ended';
    }
  }
}

/// Widget to display final call duration when call ends
/// Listens to onCallEnded stream and shows duration with 500ms delay
class CallEndedDurationDisplay extends StatefulWidget {
  final String phoneNumber;
  final CallTrackingService callTrackingService;
  final VoidCallback? onDurationReceived;

  const CallEndedDurationDisplay({
    super.key,
    required this.phoneNumber,
    required this.callTrackingService,
    this.onDurationReceived,
  });

  @override
  State<CallEndedDurationDisplay> createState() =>
      _CallEndedDurationDisplayState();
}

class _CallEndedDurationDisplayState extends State<CallEndedDurationDisplay> {
  CallData? _lastCallData;
  bool _showDuration = false;

  @override
  void initState() {
    super.initState();
    _setupCallEndedListener();
  }

  void _setupCallEndedListener() {
    widget.callTrackingService.onCallEnded.listen((callData) {
      if (_isPhoneNumberMatch(callData.phoneNumber, widget.phoneNumber)) {
        // Store the call data
        _lastCallData = callData;

        // Add 500ms delay before showing duration
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _showDuration = true;
            });

            // Notify parent widget
            widget.onDurationReceived?.call();

            // Auto-hide after 5 seconds
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _showDuration = false;
                  _lastCallData = null;
                });
              }
            });
          }
        });
      }
    });
  }

  /// Check if phone numbers match (handles different formats)
  bool _isPhoneNumberMatch(String phone1, String phone2) {
    // Clean both numbers
    String clean1 = phone1.replaceAll(RegExp(r'[^\d]'), '');
    String clean2 = phone2.replaceAll(RegExp(r'[^\d]'), '');

    // Handle country codes
    if (clean1.startsWith('91') && clean1.length == 12) {
      clean1 = clean1.substring(2);
    }
    if (clean2.startsWith('91') && clean2.length == 12) {
      clean2 = clean2.substring(2);
    }

    // Handle leading zeros
    if (clean1.startsWith('0') && clean1.length == 11) {
      clean1 = clean1.substring(1);
    }
    if (clean2.startsWith('0') && clean2.length == 11) {
      clean2 = clean2.substring(1);
    }

    return clean1 == clean2 ||
        clean1.contains(clean2) ||
        clean2.contains(clean1);
  }

  @override
  Widget build(BuildContext context) {
    if (!_showDuration || _lastCallData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timer, size: 24, color: Colors.green[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Call Duration',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontFamily: TextConstant.dmSansRegular,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _lastCallData!.duration > 0
                      ? FormatHelper.formatCallDurationWithUnits(
                        _lastCallData!.duration,
                      )
                      : 'Call not answered',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                    fontFamily: TextConstant.dmSansMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
