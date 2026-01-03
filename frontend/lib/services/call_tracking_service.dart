import 'dart:async';

import 'package:flutter/material.dart';
import 'package:telecaller_app/model/call_model.dart';

class CallTrackingService extends ChangeNotifier {
  static final CallTrackingService _instance = CallTrackingService._();
  factory CallTrackingService() => _instance;
  CallTrackingService._();

  final _callController = StreamController<CallData>.broadcast();
  Stream<CallData> get stream => _callController.stream;

  String? _phone;
  CallType? _type;
  DateTime? _answeredAt;
  bool _ended = false;

  /// Called when outgoing call is initiated
  void startOutgoing(String phone) {
    _reset();
    _phone = phone;
    _type = CallType.outgoing;

    _emit(CallData(
      phone: phone,
      duration: 0,
      state: CallState.ringing,
      type: _type!,
    ));
  }

  /// Called from native OFFHOOK / ANSWERED
  void onAnswered() {
    if (_answeredAt != null) return;

    _answeredAt = DateTime.now();

    _emit(CallData(
      phone: _phone!,
      duration: 0,
      state: CallState.answered,
      type: _type!,
      answeredAt: _answeredAt,
    ));
  }

  /// Called from native IDLE
  void onEnded() {
    if (_answeredAt == null || _ended) return;

    _ended = true;

    final endTime = DateTime.now();
    final duration =
        endTime.difference(_answeredAt!).inSeconds.clamp(1, 99999);

    _emit(CallData(
      phone: _phone!,
      duration: duration,
      state: CallState.ended,
      type: _type!,
      answeredAt: _answeredAt,
      endedAt: endTime,
    ));

    _reset();
  }

  void _emit(CallData data) {
    _callController.add(data);
    notifyListeners();
  }

  void _reset() {
    _phone = null;
    _type = null;
    _answeredAt = null;
    _ended = false;
  }

  @override
  void dispose() {
    _callController.close();
    super.dispose();
  }
}
