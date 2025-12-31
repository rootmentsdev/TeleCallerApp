// import 'package:flutter/material.dart';
// import 'package:telecaller_app/services/call_tracking_service.dart';
// import 'package:telecaller_app/utils/format_helper.dart';

// /// Widget to display real-time call duration using StreamBuilder
// class CallDurationDisplay extends StatelessWidget {
//   final CallTrackingService callTrackingService;
//   final String contactPhone;

//   const CallDurationDisplay({
//     super.key,
//     required this.callTrackingService,
//     required this.contactPhone,
//   });

//   /// Check if phone numbers match (handles different formats)
//   bool _isPhoneNumberMatch(String phone1, String phone2) {
//     // Clean both numbers
//     String clean1 = phone1.replaceAll(RegExp(r'[^\d]'), '');
//     String clean2 = phone2.replaceAll(RegExp(r'[^\d]'), '');

//     // Handle country codes
//     if (clean1.startsWith('91') && clean1.length == 12) {
//       clean1 = clean1.substring(2);
//     }
//     if (clean2.startsWith('91') && clean2.length == 12) {
//       clean2 = clean2.substring(2);
//     }

//     // Handle leading zeros
//     if (clean1.startsWith('0') && clean1.length == 11) {
//       clean1 = clean1.substring(1);
//     }
//     if (clean2.startsWith('0') && clean2.length == 11) {
//       clean2 = clean2.substring(1);
//     }

//     return clean1 == clean2 ||
//         clean1.contains(clean2) ||
//         clean2.contains(clean1);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<CallData>(
//       stream: callTrackingService.onCallData,
//       builder: (context, snapshot) {
//         // If no data, show waiting state
//         if (!snapshot.hasData) {
//           return const SizedBox.shrink();
//         }

//         final callData = snapshot.data!;

//         // Only show if phone matches
//         if (!_isPhoneNumberMatch(callData.phoneNumber, contactPhone)) {
//           return const SizedBox.shrink();
//         }

//         // Don't show this widget when call has ended - let CallEndedDurationDisplay handle it
//         if (callData.callState == CallState.ended) {
//           return const SizedBox.shrink();
//         }

//         // Build UI based on call state
//         String stateText = '';
//         IconData stateIcon = Icons.phone;
//         Color stateColor = Colors.blue;

//         switch (callData.callState) {
//           case CallState.ringing:
//             stateText = 'Ringing...';
//             stateIcon = Icons.phone_in_talk;
//             stateColor = Colors.orange;
//             break;
//           case CallState.answered:
//             stateText = 'Call Active';
//             stateIcon = Icons.phone_in_talk;
//             stateColor = Colors.green;
//             break;
//           case CallState.ended:
//             // This case is handled above, but keeping for completeness
//             stateText = 'Call Ended';
//             stateIcon = Icons.phone_disabled;
//             stateColor = Colors.red;
//             break;
//         }

//         // Format duration
//         String durationText = FormatHelper.formatCallDuration(
//           callData.duration,
//         );

//         return Container(
//           padding: const EdgeInsets.all(12),
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           decoration: BoxDecoration(
//             color: stateColor.withValues(alpha: 0.1),
//             border: Border.all(color: stateColor, width: 1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Row(
//             children: [
//               Icon(stateIcon, color: stateColor, size: 24),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       stateText,
//                       style: TextStyle(
//                         color: stateColor,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Duration: $durationText',
//                       style: TextStyle(
//                         color: stateColor.withValues(alpha: 0.8),
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               // Show source indicator
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: stateColor.withValues(alpha: 0.2),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   callData.durationSource,
//                   style: TextStyle(
//                     color: stateColor,
//                     fontSize: 10,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// /// Widget to display final call duration when call ends
// class CallEndedDurationDisplay extends StatelessWidget {
//   final CallTrackingService callTrackingService;
//   final String contactPhone;
//   final VoidCallback? onDurationReceived;

//   const CallEndedDurationDisplay({
//     super.key,
//     required this.callTrackingService,
//     required this.contactPhone,
//     this.onDurationReceived,
//   });

//   /// Check if phone numbers match (handles different formats)
//   bool _isPhoneNumberMatch(String phone1, String phone2) {
//     // Clean both numbers
//     String clean1 = phone1.replaceAll(RegExp(r'[^\d]'), '');
//     String clean2 = phone2.replaceAll(RegExp(r'[^\d]'), '');

//     // Handle country codes
//     if (clean1.startsWith('91') && clean1.length == 12) {
//       clean1 = clean1.substring(2);
//     }
//     if (clean2.startsWith('91') && clean2.length == 12) {
//       clean2 = clean2.substring(2);
//     }

//     // Handle leading zeros
//     if (clean1.startsWith('0') && clean1.length == 11) {
//       clean1 = clean1.substring(1);
//     }
//     if (clean2.startsWith('0') && clean2.length == 11) {
//       clean2 = clean2.substring(1);
//     }

//     return clean1 == clean2 ||
//         clean1.contains(clean2) ||
//         clean2.contains(clean1);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<CallData>(
//       stream: callTrackingService.onCallEnded,
//       builder: (context, snapshot) {
//         // If no data, show nothing
//         if (!snapshot.hasData) {
//           return const SizedBox.shrink();
//         }

//         final callData = snapshot.data!;

//         // Show if phone matches OR if phone is unknown/null (native may not send it on final END)
//         // In that case, we trust the stream since we're already on this contact's screen
//         final phoneMatches = _isPhoneNumberMatch(
//           callData.phoneNumber,
//           contactPhone,
//         );
//         final phoneIsUnknown =
//             callData.phoneNumber == 'Unknown' ||
//             callData.phoneNumber.isEmpty ||
//             callData.phoneNumber == 'null';

//         if (!phoneMatches && !phoneIsUnknown) {
//           return const SizedBox.shrink();
//         }

//         // Trigger callback when duration is received
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           onDurationReceived?.call();
//         });

//         // Format duration
//         String durationText = FormatHelper.formatCallDuration(
//           callData.duration,
//         );

//         return Container(
//           padding: const EdgeInsets.all(12),
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           decoration: BoxDecoration(
//             color: Colors.green.withValues(alpha: 0.1),
//             border: Border.all(color: Colors.green, width: 1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Row(
//             children: [
//               const Icon(Icons.check_circle, color: Colors.green, size: 24),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text(
//                       'Call Completed',
//                       style: TextStyle(
//                         color: Colors.green,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Final Duration: $durationText',
//                       style: const TextStyle(color: Colors.green, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//               // Show source indicator
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withValues(alpha: 0.2),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   callData.durationSource,
//                   style: const TextStyle(
//                     color: Colors.green,
//                     fontSize: 10,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
