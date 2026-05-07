import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/date_formatter.dart';

class BookedReportDetailScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String callType;
  final Map<String, dynamic>? reportData;

  const BookedReportDetailScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.callType,
    this.reportData,
  });

  @override
  State<BookedReportDetailScreen> createState() =>
      _BookedReportDetailScreenState();
}

class _BookedReportDetailScreenState extends State<BookedReportDetailScreen> {
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

  String _formatDuration(dynamic duration) {
    if (duration == null) return '00:00 Mins';

    int seconds = 0;
    if (duration is int) {
      seconds = duration;
    } else if (duration is String) {
      seconds = int.tryParse(duration) ?? 0;
    }

    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} Mins';
  }

  void _shareCallReport() {
    final data = widget.reportData ?? {};
    final shareText = '''
Booked Report

Customer: ${widget.name}
Phone: ${widget.phone}

Call Details:
Lead Type: ${_getDisplayValue(data['leadType'] ?? data['type'], 'Not available')}
Lead Status: ${_getDisplayValue(data['leadStatus'], 'Not available')}
Call Status: ${_getDisplayValue(data['callStatus'], 'Not available')}
Store: ${_getDisplayValue(data['store'] ?? data['storeName'], 'Not available')}
Location: ${_getDisplayValue(data['location'], 'Not available')}
Attended By: ${_getDisplayValue(data['attendedBy'], 'Not available')}
Call Date: ${_formatDateString(data['callDate'] ?? data['call_date'])}
Call Duration: ${_formatDuration(data['callDuration'] ?? data['call_duration'])}
Function Date: ${_formatDateString(data['functionDate'] ?? data['function_date'])}
Return Date: ${_formatDateString(data['returnDate'] ?? data['return_date'])}
Sub Category: ${_getDisplayValue(data['subCategory'] ?? data['sub_category'], 'Not available')}
Closing Reason: ${_getDisplayValue(data['closingReason'] ?? data['closing_reason'], 'Not available')}
Remarks: ${_getDisplayValue(data['remarks'], 'Not available')}
''';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.reportData ?? {};
    final leadData = data['leadData'] ?? data;

    // Extract all required fields
    final customerName = _getDisplayValue(
      data['name'] ?? data['customerName'] ?? widget.name,
      'Unknown',
    );
    final phone = _getDisplayValue(data['phone'] ?? widget.phone, 'N/A');
    final leadType = _getDisplayValue(
      data['leadType'] ?? data['type'] ?? data['leadtype'],
      'Not available',
    );
    final leadStatus = _getDisplayValue(
      data['leadStatus'] ?? data['lead_status'],
      'Not available',
    );
    final callStatus = _getDisplayValue(
      data['callStatus'] ?? data['call_status'],
      'Not available',
    );
    final store = _getDisplayValue(
      data['store'] ?? data['storeName'] ?? leadData['store'],
      'Not available',
    );
    final location = _getDisplayValue(
      data['location'] ?? data['storeName'] ?? leadData['storeName'],
      'Unknown',
    );
    final attendedBy = _getDisplayValue(
      data['attendedBy'] ?? leadData['attendedBy'],
      'Not available',
    );
    final callDate = _formatDateString(
      data['callDate'] ??
          data['call_date'] ??
          leadData['callDate'] ??
          leadData['call_date'] ??
          data['createdAt'] ??
          data['created_at'],
    );
    final callDuration = _formatDuration(
      data['callDuration'] ?? data['call_duration'],
    );
    final functionDate = _formatDateString(
      data['functionDate'] ??
          data['function_date'] ??
          leadData['functionDate'] ??
          leadData['function_date'],
    );
    final returnDate = _formatDateString(
      data['returnDate'] ??
          data['return_date'] ??
          leadData['returnDate'] ??
          leadData['return_date'],
    );
    final subCategory = _getDisplayValue(
      data['subCategory'] ??
          data['sub_category'] ??
          leadData['subCategory'] ??
          leadData['sub_category'],
      'Not available',
    );
    final closingReason = _getDisplayValue(
      data['closingReason'] ??
          data['closing_reason'] ??
          data['remarks'] ??
          leadData['closingReason'],
      'Not available',
    );
    final remarks = _getDisplayValue(
      data['remarks'] ?? leadData['remarks'],
      'Not available',
    );
    final markAsComplaint =
        data['markAsComplaint'] ??
        data['mark_as_complaint'] ??
        data['markasComplaint'] ??
        false;
    final markAsFollowup =
        data['markAsFollowup'] ??
        data['mark_as_followup'] ??
        data['markasFollowup'] ??
        false;
    final followUpDate = _formatDateString(
      data['followUpDate'] ??
          data['follow_up_date'] ??
          leadData['followUpDate'] ??
          leadData['follow_up_date'],
    );

    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Text(
                    'Reports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: TextConstant.dmSansMedium,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Card with Badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customerName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
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
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Booked',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lead Information Section
                    Text(
                      'Lead Information',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Lead Type and Lead Status
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lead Type',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                leadType,
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
                                'Lead Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                leadStatus,
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

                    // Call Status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Call Status',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          callStatus,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Call Details Section
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

                    // Store and Location
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Store',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                store,
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
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Attended By
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attended by',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          attendedBy,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Call Date and Duration
                    Row(
                      children: [
                        Expanded(
                          child: Column(
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
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                callDuration,
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

                    // Function Date and Return Date
                    Row(
                      children: [
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Return Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                returnDate,
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

                    // Sub Category
                    Column(
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
                    const SizedBox(height: 24),

                    // Additional Information Section
                    Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Closing Reason
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Closing Reason',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          closingReason,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Remarks
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remarks',
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
                    const SizedBox(height: 16),

                    // Mark As Complaint and Mark As Followup
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mark as Complaint',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                markAsComplaint ? 'Yes' : 'No',
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
                                'Mark as Followup',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                markAsFollowup ? 'Yes' : 'No',
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
                          backgroundColor: ColorConstant.primaryColor,
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
                            color: Colors.white,
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
          ),
        ],
      ),
    );
  }
}
