import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/report_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/view/reports_screens/report_details_screen.dart';
import 'package:telecaller_app/widgets.dart/app_header.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize controller with header controller
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final headerController = Provider.of<HeaderController>(
        context,
        listen: false,
      );
      final reportController = Provider.of<ReportController>(
        context,
        listen: false,
      );
      reportController.init(headerController);
      // Ensure date is set to today to show daily report
      headerController.setSelectedDate(DateTime.now());
      // Check if we should navigate to Equary Calls tab (after call save)
      reportController.checkNavigationFlag();
      // Fetch reports from API
      try {
        await reportController.fetchReportsWithCurrentFilters();
      } catch (e) {
        print('ReportScreen: Error fetching reports: $e');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reportController = Provider.of<ReportController>(
        context,
        listen: false,
      );
      // Check if we should navigate to Equary Calls tab (after call save)
      reportController.checkNavigationFlag();

      // Force refresh data from repository to ensure we have latest data
      try {
        await reportController.forceRefreshData();

        // Debug data integrity
        final leadRepository = Provider.of<LeadRepository>(
          context,
          listen: false,
        );
        leadRepository.debugDataIntegrity();
      } catch (e) {
        print('ReportScreen: Error refreshing data: $e');
      }

      // Fetch reports from API when screen becomes visible
      try {
        await reportController.fetchReportsWithCurrentFilters();
      } catch (e) {
        print('ReportScreen: Error fetching reports on screen change: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HeaderController, ReportController>(
      builder: (context, headerController, reportController, child) {
        final currentCallList = reportController.getFilteredLeads();
        // Tabs with their corresponding icons
        // Index mapping: 0=All Calls, 1=Loss of Sale, 2=Return Calls, 3=Booking Confirmation, 4=New Leads
        final tabs = [
          {"title": "All Calls", "icon": Icons.people_alt_outlined}, // Index 0
          {"title": "Loss of Sale", "icon": Icons.trending_down}, // Index 1
          {"title": "Return Calls", "icon": Icons.message_outlined}, // Index 2
          {
            "title": "Booking Confirmation",
            "icon": Icons.flag_outlined,
          }, // Index 3
          {"title": "New Leads", "icon": Icons.person_add_outlined}, // Index 4
        ];

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                showDate: true,
                showFilters: true,
                onNotificationTap: () {
                  // Handle notification tap
                },
              ),
              // Title and Back Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // GestureDetector(
                    //   onTap: () => Navigator.pop(context),
                    //   child: const Icon(
                    //     Icons.arrow_back_ios,
                    //     size: 20,
                    //     color: Colors.black87,
                    //   ),
                    // ),
                    const SizedBox(width: 16),
                    const Text(
                      "Call Completed",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs with horizontal scrolling and icons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final isSelected =
                        reportController.selectedCallTypeIndex == index;
                    final tab = tabs[index];
                    final tabTitle = tab["title"] as String;
                    final tabIcon = tab["icon"] as IconData;

                    return GestureDetector(
                      onTap: () {
                        reportController.setSelectedCallTypeIndex(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color:
                                  isSelected
                                      ? ColorConstant.primaryColor
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tabIcon,
                              size: 18,
                              color:
                                  isSelected
                                      ? ColorConstant.primaryColor
                                      : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tabTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                fontFamily: TextConstant.dmSansMedium,
                                color:
                                    isSelected
                                        ? Colors.black87
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              // Show loading, error, or content
              Expanded(
                child:
                    reportController.isLoadingReports
                        ? const Center(child: CircularProgressIndicator())
                        : reportController.reportsError != null
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading reports',
                                style: TextStyle(
                                  fontFamily: TextConstant.dmSansMedium,
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                reportController.reportsError ?? '',
                                style: TextStyle(
                                  fontFamily: TextConstant.dmSansRegular,
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await reportController
                                        .fetchReportsWithCurrentFilters();
                                  } catch (e) {
                                    // Error handled by controller
                                  }
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                        : currentCallList.isEmpty
                        ? Center(
                          child: Text(
                            reportController.selectedCallTypeIndex == 0
                                ? "No calls found"
                                : reportController.selectedCallTypeIndex == 1
                                ? "No loss of sale calls found"
                                : reportController.selectedCallTypeIndex == 2
                                ? "No Return calls found"
                                : reportController.selectedCallTypeIndex == 3
                                ? "No Booking confirmation calls found"
                                : reportController.selectedCallTypeIndex == 4
                                ? "No new leads found"
                                : "No calls found",
                            style: TextStyle(
                              fontFamily: TextConstant.dmSansRegular,
                              fontSize: 14,
                              color: ColorConstant.grey,
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: currentCallList.length,
                          itemBuilder: (context, index) {
                            final contact = currentCallList[index];
                            final category = contact["type"] as String?;
                            Color iconBgColor;
                            Color iconColor;
                            IconData icon;

                            switch (category) {
                              case "loss":
                                iconBgColor = const Color(0xFFFFE8E8);
                                iconColor = const Color(0xFFE23434);
                                icon = Icons.trending_down;
                                break;
                              case "rentout": // Used for Feedback Calls (Rent out)
                                iconBgColor = const Color(0xFFFFF7CC);
                                iconColor = const Color(0xFFFFCC00);
                                icon = Icons.message_outlined;
                                break;
                              case "booking":
                                iconBgColor = const Color(0xFFD4F5DA);
                                iconColor = const Color(0xff56BE6B);
                                icon = Icons.flag_outlined;
                                break;
                              case "justdial":
                                iconBgColor = const Color(0xFFFFE8D5);
                                iconColor = const Color(0xFFF37927);
                                icon = Icons.headset_mic_outlined;
                                break;
                              default: // All Calls
                                iconBgColor = const Color(0xFFE8E3FF);
                                iconColor = const Color(0xFF7C5DFF);
                                icon = Icons.people_alt_outlined;
                            }

                            return InkWell(
                              onTap: () {
                                // Report screen shows only reports - no calling function
                                // All leads open in ReportDetailsScreen (read-only view)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ReportDetailsScreen(
                                          contact: contact,
                                          callTypeIndex:
                                              reportController
                                                  .selectedCallTypeIndex,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  leading: Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      color: iconBgColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: iconColor,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    contact["name"]!,
                                    style: const TextStyle(
                                      fontFamily: TextConstant.dmSansMedium,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      contact["phone"]!,
                                      style: TextStyle(
                                        fontFamily: TextConstant.dmSansRegular,
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 12,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        contact["date"]!,
                                        style: TextStyle(
                                          fontFamily:
                                              TextConstant.dmSansRegular,
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}
