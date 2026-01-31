import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/report_controller.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/store_location.dart';
import 'package:telecaller_app/view/reports_screens/call_report_list_screen.dart';
import 'package:telecaller_app/view/reports_screens/report_details_screen/booking_detail_screen.dart';
import 'package:telecaller_app/view/reports_screens/report_details_screen/enquiry_detail_screen.dart';
import 'package:telecaller_app/view/reports_screens/report_details_screen/feedback_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedTimeRange = 'Last 7 Days';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

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
      // Fetch initial reports - try without date filters first to see if data exists
      reportController.fetchReportsFromApi(page: 1, limit: 100);
    });
  }

  List<String> _getTimeRanges() {
    return ['Last 7 Days', 'Today', 'This Month', 'Last Month'];
  }

  void _applyTimeRangeFilter(String range, HeaderController headerController) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (range) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'Last 7 Days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last Month':
        final firstDayThisMonth = DateTime(now.year, now.month, 1);
        endDate = firstDayThisMonth.subtract(const Duration(days: 1));
        startDate = DateTime(endDate.year, endDate.month, 1);
        break;
      default:
        startDate = now;
    }

    // Update header controller with date range
    headerController.setDateRange(startDate, endDate);
  }

  Future<void> _showCustomDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _customStartDate != null && _customEndDate != null
              ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
              : null,
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedTimeRange = 'Custom';
      });
      // Update header controller with custom date range
      if (mounted) {
        final headerController = Provider.of<HeaderController>(
          context,
          listen: false,
        );
        headerController.setDateRange(picked.start, picked.end);

        final reportController = Provider.of<ReportController>(
          context,
          listen: false,
        );
        // Fetch reports with custom date range
        reportController.fetchReportsWithCurrentFilters();
      }
    }
  }

  String _getReportCount(ReportController controller, String type) {
    final reports = controller.reports;

    print('ReportsScreen: Total reports: ${reports.length}');
    for (var r in reports) {
      print(
        'ReportsScreen: Report leadType: "${r.leadType}" (name: ${r.leadData?['name']})',
      );
    }

    switch (type) {
      case 'total':
        return reports.length.toString();
      case 'enquiry':
        final count =
            reports.where((r) => r.leadType?.toLowerCase() == 'enquiry').length;
        print('ReportsScreen: Enquiry count: $count');
        return count.toString();
      case 'feedback':
        final count =
            reports.where((r) => r.leadType?.toLowerCase() == 'return').length;
        print('ReportsScreen: Feedback count: $count');
        return count.toString();
      case 'booking':
        final count =
            reports.where((r) {
              final lt = r.leadType?.toLowerCase() ?? '';
              return lt == 'bookingconfirmation' || lt == 'booked';
            }).length;
        print('ReportsScreen: Booking count: $count');
        return count.toString();
      default:
        return '0';
    }
  }

  List<Map<String, dynamic>> _getLatestReports(ReportController controller) {
    return controller.getFilteredLeads();
  }

  String _getCallTypeDisplay(String? type) {
    switch (type?.toLowerCase()) {
      case 'enquiry':
        return 'Enquiry';
      case 'hardout':
      case 'return':
        return 'Feedback';
      case 'booking':
      case 'bookingconfirmation':
        return 'Booking';
      default:
        return 'Call';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer2<ReportController, HeaderController>(
        builder: (context, reportController, headerController, _) {
          return Column(
            children: [
              // Custom Header with notification
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
                        'Reports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: TextConstant.dmSansMedium,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Handle notification tap
                        },
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
                      // Call Reports header with Custom Range
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Call Reports',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontFamily: TextConstant.dmSansMedium,
                            ),
                          ),
                          GestureDetector(
                            onTap: _showCustomDateRangePicker,
                            child: Text(
                              'Custom Range',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Time Range Buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              _getTimeRanges().map((range) {
                                final isSelected = _selectedTimeRange == range;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedTimeRange = range;
                                        _customStartDate = null;
                                        _customEndDate = null;
                                      });
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

                      // Store Dropdown - Same as Lead Screen
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: headerController.selectedStore,
                                    isExpanded: true,
                                    dropdownColor: Colors.white,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.grey,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                    hint: const Text(
                                      "Select Store",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    items:
                                        StoreLocations.buildStoreOptions().map((
                                          String store,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: store,
                                            child: Text(
                                              store,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        headerController.setSelectedStore(
                                          newValue,
                                        );
                                        // Fetch reports with new store filter
                                        reportController
                                            .fetchReportsWithCurrentFilters();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Lead Report Section
                      Text(
                        'Lead Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: TextConstant.dmSansMedium,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Report Cards - Row Column Layout
                      Column(
                        children: [
                          // First Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildReportCard(
                                  icon: Icons.phone,
                                  count: _getReportCount(
                                    reportController,
                                    'total',
                                  ),
                                  title: 'Total Calls',
                                  iconBgColor: const Color(0xFFE3F2FD),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildReportCard(
                                  icon: Icons.chat_bubble,
                                  count: _getReportCount(
                                    reportController,
                                    'enquiry',
                                  ),
                                  title: 'Enquiry Calls',
                                  iconBgColor: const Color(0xFFE3F2FD),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Second Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildReportCard(
                                  icon: Icons.feedback,
                                  count: _getReportCount(
                                    reportController,
                                    'feedback',
                                  ),
                                  title: 'Feedback Calls',
                                  iconBgColor: const Color(0xFFE3F2FD),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildReportCard(
                                  icon: Icons.people,
                                  count: _getReportCount(
                                    reportController,
                                    'booking',
                                  ),
                                  title: 'Booking Calls',
                                  iconBgColor: const Color(0xFFE3F2FD),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Latest Call Report Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Latest Call Report',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontFamily: TextConstant.dmSansMedium,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const CallReportListScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'View All',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Call Report Cards - Show latest 3 reports
                      if (reportController.isLoadingReports)
                        const Center(child: CircularProgressIndicator())
                      else if (reportController.reports.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No reports available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const CallReportListScreen(),
                              ),
                            );
                          },
                          child: Column(
                            children:
                                _getLatestReports(
                                  reportController,
                                ).take(3).map((report) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildCallReportCard(
                                      name: report['name'] ?? 'Unknown',
                                      phone: report['phone'] ?? 'N/A',
                                      store:
                                          report['storeName'] ??
                                          'Not available',
                                      date: report['date'] ?? 'N/A',
                                      callType: _getCallTypeDisplay(
                                        report['type'],
                                      ),
                                      callTypeColor: const Color(0xFFE3F2FD),
                                      callTypeTextColor: const Color(
                                        0xFF1976D2,
                                      ),
                                      report: report,
                                    ),
                                  );
                                }).toList(),
                          ),
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

  Widget _buildReportCard({
    required IconData icon,
    required String count,
    required String title,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: ColorConstant.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColorConstant.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: ColorConstant.primaryColor,
              fontFamily: TextConstant.dmSansRegular,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallReportCard({
    required String name,
    required String phone,
    required String store,
    required String date,
    required String callType,
    required Color callTypeColor,
    required Color callTypeTextColor,
    required Map<String, dynamic> report,
  }) {
    return Container(
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
                  color: callTypeColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  callType,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: callTypeTextColor,
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
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: TextConstant.dmSansRegular,
                ),
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
