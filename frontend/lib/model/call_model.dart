enum CallState { ringing, answered, ended }
enum CallType { incoming, outgoing }

class CallData {
  final String phone;
  final int duration;
  final CallState state;
  final CallType type;
  final DateTime? answeredAt;
  final DateTime? endedAt;

  CallData({
    required this.phone,
    required this.duration,
    required this.state,
    required this.type,
    this.answeredAt,
    this.endedAt,
  });
}
