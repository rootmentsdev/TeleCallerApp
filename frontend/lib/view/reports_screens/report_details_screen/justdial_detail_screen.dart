import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/date_formatter.dart';

class JustDialDetailScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String callType;
  final Map<String, dynamic>? reportData;

  const JustDialDetailScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.callType,
    this.reportData,
  });

  @override
  State<JustDialDetailScreen> createState() => _JustDialDetailScreenState();
}

class _JustDialDetailScreenState extends State<JustDialDetailScreen> {
  String _getDisplayValue(dynamic value, String defaultValue) {
    if (value == null || value.toString().isEmpty) {
      return defaultValue;
    }
    return value.toString();
  }

  /// Format ISO date string to readable format (e.g., "29 Jan, 2026")
  String _formatDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not available';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormatter.formatDate(date);
    } catch (e) {
      return dateString;
    }
  }

  void _shareCallReport() {
    final data = widget.reportData ?? {};
    final shareText = '''
JustDial Call Report

Customer: ${widget.name}
Phone: ${widget.phone}

Call Details:
Call Date: ${_getDisplayValue(data['callDate'], 'Not available')}
Location: ${_getDisplayValue(data['storeName'], 'Not available')}
Sub Category: ${_getDisplayValue(data['subCategory'], 'Not available')}
Item Category: ${_getDisplayValue(data['itemCategory'], 'Not available')}
Close Action: ${_getDisplayValue(data['closingAction'], 'Not available')}
Remarks: ${_getDisplayValue(data['remarks'], 'Not available')}
''';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.reportData ?? {};

    // Extract leadSnapshot from reportData (ReportModel structure)
    // If reportData is a ReportModel converted to map, it has 'leadSnapshot' key
    // If reportData is just lead data, use it directly
    final leadSnapshot = data['leadSnapshot'] as Map<String, dynamic>? ?? data;
    final leadData = data['leadData'] as Map<String, dynamic>? ?? leadSnapshot;

    // Extract call date - check multiple possible field names
    final callDateRaw = _getDisplayValue(
      data['callDate'] ??
          data['date'] ??
          data['createdAt'] ??
          data['created_at'] ??
          leadData['created_at'] ??
          leadData['createdAt'] ??
          leadSnapshot['created_at'] ??
          leadSnapshot['createdAt'],
      'Not available',
    );
    final callDate = _formatDateString(callDateRaw);

    // Extract location - JustDial uses city, area, brancharea fields
    final location = _getDisplayValue(
      data['storeName'] ??
          data['store'] ??
          data['location'] ??
          leadData['store'] ??
          leadData['storeName'] ??
          leadData['location'] ??
          leadData['brancharea'] ??
          leadData['area'] ??
          leadData['city'] ??
          leadSnapshot['store'] ??
          leadSnapshot['storeName'] ??
          leadSnapshot['location'] ??
          leadSnapshot['brancharea'] ??
          leadSnapshot['area'] ??
          leadSnapshot['city'],
      'Not available',
    );

    // Extract sub category
    final subCategory = _getDisplayValue(
      data['subCategory'] ??
          data['sub_category'] ??
          leadData['subCategory'] ??
          leadData['sub_category'] ??
          leadSnapshot['subCategory'] ??
          leadSnapshot['sub_category'],
      'Not available',
    );

    // Extract item category
    final itemCategory = _getDisplayValue(
      data['itemCategory'] ??
          data['item_category'] ??
          leadData['itemCategory'] ??
          leadData['item_category'] ??
          leadSnapshot['itemCategory'] ??
          leadSnapshot['item_category'],
      'Not available',
    );

    // Extract closing action / status
    final closingAction = _getDisplayValue(
      data['closingAction'] ??
          data['closing_action'] ??
          leadData['closingAction'] ??
          leadData['closing_action'] ??
          leadSnapshot['closingAction'] ??
          leadSnapshot['closing_action'],
      'Not available',
    );

    // Extract remarks - check multiple field names
    final remarks = _getDisplayValue(
      data['remarks'] ??
          data['reason'] ??
          leadData['remarks'] ??
          leadData['reason'] ??
          leadSnapshot['remarks'] ??
          leadSnapshot['reason'],
      'Not available',
    );

    // Extract call duration - check both top-level and nested
    final callDuration =
        data['callDuration'] != null
            ? '${data['callDuration']}s'
            : (data['call_duration'] != null
                ? '${data['call_duration']}s'
                : (leadData['callDuration'] != null
                    ? '${leadData['callDuration']}s'
                    : (leadData['call_duration'] != null
                        ? '${leadData['call_duration']}s'
                        : (leadSnapshot['callDuration'] != null
                            ? '${leadSnapshot['callDuration']}s'
                            : (leadSnapshot['call_duration'] != null
                                ? '${leadSnapshot['call_duration']}s'
                                : 'Not available')))));

    // Extract follow-up date
    final followUpDateRaw = _getDisplayValue(
      data['followUpDate'] ??
          data['follow_up_date'] ??
          leadData['followUpDate'] ??
          leadData['follow_up_date'] ??
          leadSnapshot['followUpDate'] ??
          leadSnapshot['follow_up_date'],
      'Not available',
    );
    final followUpDate = _formatDateString(followUpDateRaw);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            color: ColorConstant.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: TextConstant.dmSansMedium,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Info Card - JustDial Orange Theme
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.phone,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE65100),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'JustDial',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Call Details Section Header
                  Text(
                    'Call Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: TextConstant.dmSansMedium,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Call Date with duration badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Call Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: TextConstant.dmSansRegular,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            callDate,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          callDuration,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: TextConstant.dmSansRegular,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sub Category and Close Action
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sub Category',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: TextConstant.dmSansRegular,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subCategory,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Close Action',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: TextConstant.dmSansRegular,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              closingAction,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Item Category
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Category',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: TextConstant.dmSansRegular,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        itemCategory,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remarks / Notes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: TextConstant.dmSansRegular,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remarks,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Follow Up Section
                  Text(
                    'Follow Up',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: TextConstant.dmSansMedium,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Follow Up Call Date with badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Call Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: TextConstant.dmSansRegular,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            followUpDate,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          callDuration,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Closing Action in Follow Up
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Closing Action',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: TextConstant.dmSansRegular,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        closingAction,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Remarks in Follow Up
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remarks / Notes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: TextConstant.dmSansRegular,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remarks,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Share Call Report Button - JustDial Orange Theme
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _shareCallReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF3E0),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Share Call Report',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
