import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/report_controller.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/date_categorization.dart';
import 'package:telecaller_app/view/reports_screens/report_details_screen/booking_detail_screen.dart';
import 'package:telecaller_app/view/reports_screens/report_details_screen/enquiry_detail_screen.dart';
import 'package:telecaller_app/view/reports_screens/report_details_screen/feedback_detail_screen.dart';

class CallReportListScreen extends StatefulWidget {
  const CallReportListScreen({super.key});

  @override
  State<CallReportListScreen> createState() => _CallReportListScreenState();
}

class _CallReportListScreenState extends State<CallReportListScreen> {
  String _selectedTimeRange = 'Last 7 Days';
  String _selectedCallType = 'All';

  final List<String> timeRanges = [
    'Last 7 Days',
    'Today',
    'This Month',
    'Last Month',
  ];

  final List<String> callTypes = [
    'All',
    'Feedback',
    'Enquiry',
    'Booking',
    'Booking Confirmation',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize report controller with header controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportController = Provider.of<ReportController>(
        context,
        listen: false,
      );
      final headerController = Provider.of<HeaderController>(
        context,
        listen: false,
      );
      reportController.init(headerController);
      // Set initial date category to "Last 7 Days"
      reportController.setSelectedDateCategory('Last 7 Days');
      // Set initial date range for "Last 7 Days"
      _applyTimeRangeFilter(_selectedTimeRange, headerController);
      // Fetch initial reports
      reportController.fetchReportsWithCurrentFilters();
    });
  }

  void _applyTimeRangeFilter(String range, HeaderController headerController) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (range) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Last 7 Days':
        startDate = now.subtract(const Duration(days: 7));
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Last Month':
        final firstDayThisMonth = DateTime(now.year, now.month, 1);
        endDate = firstDayThisMonth.subtract(const Duration(days: 1));
        endDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        startDate = DateTime(endDate.year, endDate.month, 1);
        break;
      default:
        startDate = now;
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    // Update header controller with date range
    headerController.setDateRange(startDate, endDate);
  }

  List<Map<String, dynamic>> _getFilteredReports(
    List<Map<String, dynamic>> allReports,
  ) {
    // First, filter by date category using local filtering
    final dateFilteredReports =
        allReports.where((report) {
          try {
            final leadData = report['leadData'] as Map<String, dynamic>? ?? {};
            dynamic createdAtValue =
                leadData['createdAt'] ?? report['callDate'];

            if (createdAtValue == null) return false;

            DateTime reportDate;
            if (createdAtValue is String) {
              reportDate = DateTime.parse(createdAtValue);
            } else if (createdAtValue is DateTime) {
              reportDate = createdAtValue;
            } else {
              return false;
            }

            final normalizedReportDate = DateTime(
              reportDate.year,
              reportDate.month,
              reportDate.day,
            );
            return DateCategorization.isDateInCategory(
              normalizedReportDate,
              _selectedTimeRange,
            );
          } catch (e) {
            return false;
          }
        }).toList();

    // Then filter out invalid lead types (only keep Enquiry, Feedback, Booking)
    final validReports =
        dateFilteredReports.where((report) {
          final callType = _getCallTypeDisplay(report['type']);
          return callType != 'Call'; // Exclude unknown types
        }).toList();

    // Remove duplicates based on phone number and lead type
    final seen = <String>{};
    final deduplicatedReports = <Map<String, dynamic>>[];

    for (final report in validReports) {
      final phone = report['phone'] ?? '';
      final type = report['type'] ?? '';
      final key = '$phone-$type';

      if (!seen.contains(key)) {
        seen.add(key);
        deduplicatedReports.add(report);
      }
    }

    if (_selectedCallType == 'All') {
      return deduplicatedReports;
    }

    return deduplicatedReports.where((report) {
      final callType = _getCallTypeDisplay(report['type']);
      return callType == _selectedCallType;
    }).toList();
  }

  String _getCallTypeDisplay(String? type) {
    switch (type?.toLowerCase()) {
      case 'enquiry':
        return 'Enquiry';
      case 'hardout':
      case 'return':
        return 'Feedback';
      case 'booking':
        return 'Booking';
      case 'bookingconfirmation':
      case 'booking confirmation':
        return 'Booking Confirmation';
      default:
        return 'Call'; // Unknown type - will be filtered out
    }
  }

  Color _getCallTypeColor(String callType) {
    switch (callType) {
      case 'Feedback':
        return const Color(0xFFE3F2FD);
      case 'Enquiry':
        return const Color(0xFFF3E5F5);
      case 'Booking':
        return const Color(0xFFE8F5E9);
      case 'Booking Confirmation':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  Color _getCallTypeTextColor(String callType) {
    switch (callType) {
      case 'Feedback':
        return const Color(0xFF1976D2);
      case 'Enquiry':
        return const Color(0xFF7B1FA2);
      case 'Booking':
        return const Color(0xFF388E3C);
      case 'Booking Confirmation':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF1976D2);
    }
  }

  // Parse callDuration - API returns as String, need to convert to int
  int? _parseCallDuration(dynamic callDur) {
    if (callDur == null) return null;
    if (callDur is int) return callDur;
    if (callDur is String) {
      try {
        return int.parse(callDur);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) {
      return '0s';
    }
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer2<ReportController, HeaderController>(
        builder: (context, reportController, headerController, _) {
          final allReports = reportController.getFilteredLeads();
          final filteredReports = _getFilteredReports(allReports);

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: ColorConstant.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Call Reports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: TextConstant.dmSansMedium,
                        ),
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
                      // Time Range Buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              timeRanges.map((range) {
                                final isSelected = _selectedTimeRange == range;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(
                                        () => _selectedTimeRange = range,
                                      );
                                      // Set date category for local filtering
                                      reportController.setSelectedDateCategory(
                                        range,
                                      );
                                      // Apply time range filter to header controller
                                      _applyTimeRangeFilter(
                                        range,
                                        headerController,
                                      );
                                      // Fetch reports with new time range
                                      reportController
                                          .fetchReportsWithCurrentFilters();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? ColorConstant.primaryColor
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? ColorConstant.primaryColor
                                                  : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        range,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                          fontFamily: TextConstant.dmSansMedium,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Store Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              headerController.selectedStore.normalizedName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontFamily: TextConstant.dmSansMedium,
                              ),
                            ),
                            Icon(Icons.expand_more, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Call Type Filter
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              callTypes.map((type) {
                                final isSelected = _selectedCallType == type;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedCallType = type);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? ColorConstant.primaryColor
                                                : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        type,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                          fontFamily: TextConstant.dmSansMedium,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Call Reports List
                      if (reportController.isLoadingReports)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (filteredReports.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No call reports found',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontFamily: TextConstant.dmSansRegular,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            final callType = _getCallTypeDisplay(
                              report['type'],
                            );
                            return _buildCallReportCard(
                              name: report['name'] ?? 'Unknown',
                              phone: report['phone'] ?? 'N/A',
                              store: report['storeName'] ?? 'Not available',
                              date: report['date'] ?? 'N/A',
                              callType: callType,
                              duration: _formatDuration(
                                _parseCallDuration(report['callDuration']),
                              ),
                              report: report,
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCallReportCard({
    required String name,
    required String phone,
    required String store,
    required String date,
    required String callType,
    required String duration,
    required Map<String, dynamic> report,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 12,
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
                  color: _getCallTypeColor(callType),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  callType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getCallTypeTextColor(callType),
                    fontFamily: TextConstant.dmSansMedium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            store,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: TextConstant.dmSansRegular,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: TextConstant.dmSansRegular,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Duration: $duration',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: TextConstant.dmSansRegular,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Widget detailScreen;
                  if (callType == 'Enquiry') {
                    detailScreen = EnquiryDetailScreen(
                      name: name,
                      phone: phone,
                      callType: callType,
                      reportData: report,
                    );
                  } else if (callType == 'Feedback') {
                    detailScreen = FeedbackDetailScreen(
                      name: name,
                      phone: phone,
                      callType: callType,
                      reportData: report,
                    );
                  } else {
                    detailScreen = BookingDetailScreen(
                      name: name,
                      phone: phone,
                      callType: callType,
                      reportData: report,
                    );
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => detailScreen),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'Details',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Color(0xFF2196F3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
