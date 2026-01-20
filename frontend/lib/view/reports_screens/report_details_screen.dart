import 'package:flutter/material.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/date_formatter.dart';

class ReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> contact;
  final int callTypeIndex;

  const ReportDetailsScreen({
    super.key,
    required this.contact,
    required this.callTypeIndex,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  int? _callDuration;
  bool _isLoadingDuration = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Initialize with contact data if available (check both formats)
    _callDuration =
        widget.contact["callDuration"] as int? ??
        widget.contact["call_duration"] as int?;
    // Fetch latest call duration from backend if not already available
    // Note: Only fetch if duration is null (not if it's 0, as 0 is a valid duration for unanswered calls)
    if (_callDuration == null) {
      _fetchCallDuration();
    }
  }

  Future<void> _fetchCallDuration() async {
    final leadId = widget.contact["id"] as String?;
    if (leadId == null) return;

    // If duration already exists in contact (including 0), use it and don't fetch
    if (_callDuration != null) {
      return;
    }

    setState(() {
      _isLoadingDuration = true;
    });

    try {
      final response = await _apiService.getReportById(leadId);

      print('ReportDetailsScreen: Report response: $response');

      // Extract call_duration from response - check multiple possible locations
      final callDuration =
          response["call_duration"] as int? ??
          response["callDuration"] as int? ??
          response["data"]?["call_duration"] as int? ??
          response["data"]?["callDuration"] as int? ??
          response["report"]?["call_duration"] as int? ??
          response["report"]?["callDuration"] as int?;

      print('ReportDetailsScreen: Extracted call duration: $callDuration');

      if (mounted) {
        setState(() {
          _callDuration = callDuration;
          _isLoadingDuration = false;
        });
      }
    } catch (e) {
      print('ReportDetailsScreen: Error fetching call duration: $e');
      if (mounted) {
        setState(() {
          _isLoadingDuration = false;
        });
      }
    }
  }

  Map<String, dynamic> get contact => widget.contact;
  int get callTypeIndex => widget.callTypeIndex;

  String get screenSubtitle {
    final storeName = contact["storeName"] ?? "Store";
    String category = "";

    switch (callTypeIndex) {
      case 0:
        category = "All Calls";
        break;
      case 1:
        category = "Loss of Sale";
        break;
      case 2:
        category = "Feedback Calls";
        break;
      case 3:
        category = "Follow-up";
        break;
      case 4:
        category = "Just Dial";
        break;
      case 6:
        category = "Follow-up";
        break;
      default:
        category = "All Calls";
    }

    return "$storeName | $category";
  }

  String _formatCallDuration(int? seconds) {
    if (seconds == null || seconds <= 0) {
      return "00:00 mins";
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')} mins";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (callTypeIndex == 2) // Feedback Calls - index 2
                            // const Icon(
                            //   Icons.message_outlined,
                            //   color: Colors.white,
                            //   size: 18,
                            // ),
                            if (callTypeIndex == 2) const SizedBox(width: 8),
                          const Text(
                            "Call Completed",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: TextConstant.dmSansMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        screenSubtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontFamily: TextConstant.dmSansRegular,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
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
                    // Customer Information Section
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact["name"] ?? "",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: TextConstant.dmSansMedium,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    contact["phone"] ?? "",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                      fontFamily: TextConstant.dmSansRegular,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Call Duration Badge - Light Blue Pill Container (matching image)
                                  if (_callDuration != null ||
                                      _isLoadingDuration)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.blue[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.timer,
                                            size: 14,
                                            color: Colors.blue[700],
                                          ),
                                          const SizedBox(width: 6),
                                          _isLoadingDuration
                                              ? SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.blue[700]!),
                                                ),
                                              )
                                              : Text(
                                                _formatCallDuration(
                                                  _callDuration ?? 0,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue[700],
                                                  fontFamily:
                                                      TextConstant.dmSansMedium,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Report Details - Read Only
                    _buildReadOnlyDetailsSection(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateField(dynamic dateValue) {
    if (dateValue == null ||
        dateValue.toString().isEmpty ||
        dateValue == "Not available") {
      return "Not available";
    }
    try {
      final date =
          dateValue is DateTime
              ? dateValue
              : DateTime.parse(dateValue.toString());
      return DateFormatter.formatDate(date);
    } catch (e) {
      return dateValue.toString();
    }
  }

  Widget _buildReadOnlyDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Three column date layout
        Row(
          children: [
            Expanded(
              child: _buildDetailRow(
                "Visit Date",
                _formatDateField(
                  contact["visitDate"] ??
                      contact["visit_date"] ??
                      contact["date"],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailRow(
                "Function Date",
                _formatDateField(
                  contact["functionDate"] ?? contact["function_date"],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailRow(
                "Call Date",
                _formatDateField(
                  contact["callDate"] ??
                      contact["date"] ??
                      contact["created_at"],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          "Attended By",
          contact["attendedBy"] ?? contact["attended_by"] ?? "Not available",
        ),
        const SizedBox(height: 16),
        // Reason Collected From Store
        _buildDetailRow(
          "Reason Collected From Store",
          contact["reason_collected_from_store"] ??
              contact["reasonFromStore"] ??
              contact["reason"] ??
              "No reason provided",
          isMultiline: true,
        ),
        const SizedBox(height: 16),
        // Call Status and Lead Status as badges
        Row(
          children: [
            Expanded(
              child: _buildStatusBadge(
                "Call Status",
                contact["callStatus"] ??
                    contact["call_status"] ??
                    "Not available",
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusBadge(
                "Lead Status",
                contact["leadStatus"] ??
                    contact["lead_status"] ??
                    "Not available",
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Rating (for Feedback Calls)
        if (callTypeIndex == 2) // Feedback Calls
          _buildRatingDisplay(),
        if (callTypeIndex == 2) // Feedback Calls
          const SizedBox(height: 16),
        // Follow Up Date
        if (contact["followUpDate"] != null ||
            contact["follow_up_date"] != null ||
            contact["followUp"] != null ||
            contact["follow_up"] != null)
          _buildDetailRow(
            "Follow Up Date",
            _formatDateField(
              contact["followUpDate"] ??
                  contact["follow_up_date"] ??
                  contact["followUp"] ??
                  contact["follow_up"],
            ),
          ),
        if (contact["followUpDate"] != null ||
            contact["follow_up_date"] != null ||
            contact["followUp"] != null ||
            contact["follow_up"] != null)
          const SizedBox(height: 16),
        // Remarks
        _buildDetailRow(
          "Remarks",
          contact["remarks"] ?? "No remarks",
          isMultiline: true,
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xff171717),
            fontFamily: TextConstant.dmSansRegular,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
            fontFamily: TextConstant.dmSansMedium,
            height: isMultiline ? 1.4 : 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, String value, Color color) {
    // Get darker shade of the color
    final Color darkerColor = Color.fromRGBO(
      (color.red * 0.7).round().clamp(0, 255),
      (color.green * 0.7).round().clamp(0, 255),
      (color.blue * 0.7).round().clamp(0, 255),
      1.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xff171717),
            fontFamily: TextConstant.dmSansRegular,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: darkerColor,
              fontFamily: TextConstant.dmSansMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDisplay() {
    // Get rating from contact data
    final ratingValue = contact["rating"];
    int rating = 0;

    if (ratingValue != null) {
      if (ratingValue is int) {
        rating = ratingValue;
      } else if (ratingValue is String) {
        rating = int.tryParse(ratingValue) ?? 0;
      } else if (ratingValue is double) {
        rating = ratingValue.round();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Rating",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xff171717),
            fontFamily: TextConstant.dmSansRegular,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              Icons.star,
              size: 28,
              color: index < rating ? Colors.amber : Colors.grey[300],
            );
          }),
        ),
        if (rating > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "$rating out of 5",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: TextConstant.dmSansRegular,
              ),
            ),
          ),
      ],
    );
  }
}
