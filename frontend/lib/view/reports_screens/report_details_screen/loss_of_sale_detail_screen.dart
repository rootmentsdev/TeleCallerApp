import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/date_formatter.dart';

class LossOfSaleDetailScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String callType;
  final Map<String, dynamic>? reportData;

  const LossOfSaleDetailScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.callType,
    this.reportData,
  });

  @override
  State<LossOfSaleDetailScreen> createState() => _LossOfSaleDetailScreenState();
}

class _LossOfSaleDetailScreenState extends State<LossOfSaleDetailScreen> {
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
Call Report - ${widget.callType}

Customer: ${widget.name}
Phone: ${widget.phone}

Call Details:
Call Date: ${_getDisplayValue(data['callDate'], 'Not available')}
Location: ${_getDisplayValue(data['storeName'], 'Not available')}
Function Date: ${_getDisplayValue(data['functionDate'], 'Not available')}
Sub Category: ${_getDisplayValue(data['subCategory'], 'Not available')}
Close Action: ${_getDisplayValue(data['closingAction'], 'Not available')}
Remarks: ${_getDisplayValue(data['remarks'], 'Not available')}

Follow Up:
Follow Up Date: ${_getDisplayValue(data['followUpDate'], 'Not available')}
''';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.reportData ?? {};
    final leadData = data['leadData'] ?? data;

    final callDateRaw = _getDisplayValue(
      data['callDate'] ??
          data['date'] ??
          leadData['created_at'] ??
          leadData['createdAt'],
      'Not available',
    );
    final callDate = _formatDateString(callDateRaw);
    final location = _getDisplayValue(
      data['storeName'] ?? leadData['store'] ?? leadData['storeName'],
      'Not available',
    );
    final functionDateRaw = _getDisplayValue(
      data['functionDate'] ??
          data['function_date'] ??
          leadData['functionDate'] ??
          leadData['function_date'] ??
          callDateRaw,
      'Not available',
    );
    final functionDate = _formatDateString(functionDateRaw);
    final subCategory = _getDisplayValue(
      data['subCategory'] ??
          data['sub_category'] ??
          leadData['subCategory'] ??
          leadData['sub_category'],
      'Not available',
    );
    final closingAction = _getDisplayValue(
      data['closingAction'] ??
          data['closing_action'] ??
          leadData['closingAction'] ??
          leadData['closing_action'],
      'Not available',
    );
    final remarks = _getDisplayValue(
      data['remarks'] ?? leadData['remarks'] ?? leadData['reason'],
      'Not available',
    );
    final followUpDateRaw = _getDisplayValue(
      data['followUpDate'] ??
          data['follow_up_date'] ??
          leadData['followUpDate'] ??
          leadData['follow_up_date'],
      'Not available',
    );
    final followUpDate = _formatDateString(followUpDateRaw);
    final callDuration =
        data['callDuration'] != null
            ? '${data['callDuration']}s'
            : (data['call_duration'] != null
                ? '${data['call_duration']}s'
                : 'Not available');

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
                        'Loss of Sale',
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
                  // Customer Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
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
                            color: ColorConstant.primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.callType,
                            style: const TextStyle(
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
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          callDuration,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location and Function Date
                  Row(
                    children: [
                      Expanded(
                        child: Column(
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
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Function Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: TextConstant.dmSansRegular,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              functionDate,
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

                  // Remarks / Notes
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

                  // Follow Up Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Follow Up Date',
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
                  const SizedBox(height: 24),

                  // Share Call Report Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _shareCallReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3F2FD),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Share Call Report',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorConstant.primaryColor,
                          fontFamily: TextConstant.dmSansMedium,
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
