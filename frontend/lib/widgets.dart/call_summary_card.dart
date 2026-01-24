// import 'package:flutter/material.dart';
// import 'package:telecaller_app/view/call_summary_details_screen.dart';

// class CallSummaryCard extends StatelessWidget {
//   final String title;
//   final String count;
//   final Color bgColor;
//   final Color iconColor;
//   final IconData icon;
//   final VoidCallback? onTap;
//   final bool isSelected;
//   final BuildContext? context;
//   final String? callType;
//   final bool isStarred;

//   const CallSummaryCard({
//     super.key,
//     required this.title,
//     required this.count,
//     required this.bgColor,
//     required this.iconColor,
//     required this.icon,
//     this.onTap,
//     this.isSelected = false,
//     this.context,
//     this.callType,
//     this.isStarred = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         // First execute the onTap callback if provided
//         onTap?.call();

//         // Then navigate to details screen if context and callType are provided
//         if (this.context != null && callType != null) {
//           Navigator.push(
//             this.context!,
//             MaterialPageRoute(
//               builder:
//                   (context) => CallSummaryDetailsScreen(
//                     title: title,
//                     bgColor: bgColor,
//                     iconColor: iconColor,
//                     icon: icon,
//                     callType: callType!,
//                   ),
//             ),
//           );
//         }
//       },
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Stack(
//             clipBehavior: Clip.none,
//             children: [
//               Container(
//                 height: 48,
//                 width: 48,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                   color: bgColor,
//                   border:
//                       isSelected
//                           ? Border.all(color: iconColor, width: 2)
//                           : null,
//                 ),
//                 child: Icon(icon, color: iconColor, size: 20),
//               ),
//               Positioned(
//                 bottom: -6,
//                 right: -6,
//                 child: Container(
//                   constraints: const BoxConstraints(
//                     minHeight: 26,
//                     minWidth: 26,
//                   ),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 6,
//                     vertical: 2,
//                   ),
//                   alignment: Alignment.center,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: iconColor.withValues(alpha: 0.3),
//                         blurRadius: 4,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Text(
//                     count,
//                     style: TextStyle(
//                       fontSize: count.length > 2 ? 10 : 12,
//                       fontWeight: FontWeight.bold,
//                       color: iconColor,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             title,
//             textAlign: TextAlign.center,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               fontSize: 10,
//               color: Colors.grey[800],
//               fontWeight: FontWeight.w600,
//               height: 1.2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
