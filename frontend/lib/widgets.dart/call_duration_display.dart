import 'dart:async';
import 'package:flutter/material.dart';
import 'package:telecaller_app/model/call_model.dart';
import 'package:telecaller_app/services/call_tracking_service.dart';
import 'package:telecaller_app/utils/format_helper.dart';
import 'package:telecaller_app/utils/text_constant.dart';

class CallStatusDisplay extends StatefulWidget {
  final String phoneNumber;
  final CallTrackingService service;

  const CallStatusDisplay({
    super.key,
    required this.phoneNumber,
    required this.service,
  });

  @override
  State<CallStatusDisplay> createState() => _CallStatusDisplayState();
}

class _CallStatusDisplayState extends State<CallStatusDisplay> {
  StreamSubscription<CallData>? _sub;
  CallData? _data;
  bool _visible = false;

  @override
  void initState() {
    super.initState();

    _sub = widget.service.stream.listen((data) {
      if (!_isSamePhone(data.phone, widget.phoneNumber)) return;

      setState(() {
        _data = data;
        _visible = true;
      });

      // Auto-hide ONLY after ended
      if (data.state == CallState.ended) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _visible = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _data == null) return const SizedBox.shrink();

    final isEnded = _data!.state == CallState.ended;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEnded ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnded ? Colors.green[300]! : Colors.blue[300]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          _icon(isEnded),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(_data!.state),
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnded ? Colors.green[700] : Colors.blue[700],
                    fontFamily: TextConstant.dmSansRegular,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _valueText(_data!),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isEnded ? Colors.green[800] : Colors.blue[800],
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

  Widget _icon(bool ended) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ended ? Colors.green[100] : Colors.blue[100],
        shape: BoxShape.circle,
      ),
      child: Icon(
        ended ? Icons.timer : Icons.phone_in_talk,
        color: ended ? Colors.green[700] : Colors.blue[700],
        size: 24,
      ),
    );
  }

  String _title(CallState state) {
    switch (state) {
      case CallState.ringing:
        return 'Calling...';
      case CallState.answered:
        return 'On Call';
      case CallState.ended:
        return 'Call Duration';
    }
  }

  String _valueText(CallData data) {
    if (data.state == CallState.ended) {
      return FormatHelper.formatCallDurationWithUnits(data.duration);
    }
    if (data.state == CallState.answered) {
      return 'Connected';
    }
    return 'Ringing...';
  }

  bool _isSamePhone(String a, String b) {
    String c1 = a.replaceAll(RegExp(r'[^\d]'), '');
    String c2 = b.replaceAll(RegExp(r'[^\d]'), '');

    if (c1.startsWith('91') && c1.length == 12) c1 = c1.substring(2);
    if (c2.startsWith('91') && c2.length == 12) c2 = c2.substring(2);

    if (c1.startsWith('0') && c1.length == 11) c1 = c1.substring(1);
    if (c2.startsWith('0') && c2.length == 11) c2 = c2.substring(1);

    return c1 == c2;
  }
}
