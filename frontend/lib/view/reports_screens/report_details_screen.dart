import 'package:flutter/material.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/format_helper.dart';

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
    // Initialize with contact data if available
    _callDuration = widget.contact["callDuration"] as int?;
    // Fetch latest call duration from backend
    _fetchCallDuration();
  }

  Future<void> _fetchCallDuration() async {
    final leadId = widget.contact["id"] as String?;
    if (leadId == null) return;

    setState(() {
      _isLoadingDuration = true;
    });

    try {
      final response = await _apiService.getReportById(leadId);
      
      // Extract call_duration from response
      final callDuration = response["call_duration"] as int? ?? 
                          response["callDuration"] as int? ??
                          response["data"]?["call_duration"] as int? ??
                          response["data"]?["callDuration"] as int?;

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
        category = "Return Calls";
        break;
      case 3:
        category = "Booking Calls";
        break;
      case 4:
        category = "Just Dial";
        break;
      case 5:
        category = "New Leads";
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
    return FormatHelper.formatCallDurationWithUnits(seconds);
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Report Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
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
                                  // Call Duration Badge - Small Container
                                  if (_callDuration != null && _callDuration! > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.green[300]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.timer,
                                            size: 12,
                                            color: Colors.green[700],
                                          ),
                                          const SizedBox(width: 4),
                                          _isLoadingDuration
                                              ? SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 1.5,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      Colors.green[700]!,
                                                    ),
                                                  ),
                                                )
                                              : Text(
                                                  _formatCallDuration(_callDuration),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.green[700],
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
                contact["visitDate"] ?? contact["date"] ?? "Not available",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailRow(
                "Function Date",
                contact["functionDate"] ?? "Not available",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailRow(
                "Call Date",
                contact["callDate"] ?? contact["date"] ?? "Not available",
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          "Attended By",
          contact["attendedBy"] ?? "Not available",
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          "Call Status",
          contact["callStatus"] ?? "Not available",
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          "Lead Status",
          contact["leadStatus"] ?? "Not available",
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          "Reason",
          contact["reasonFromStore"] ??
              contact["reason"] ??
              "No reason provided",
          isMultiline: true,
        ),
        const SizedBox(height: 16),
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
}
