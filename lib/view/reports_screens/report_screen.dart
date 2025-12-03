import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/report_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/view/reports_screens/report_details_screen.dart';
import 'package:telecaller_app/view/reports_screens/just_dial_details_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      // Refresh to show updated leads
      reportController.refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportController = Provider.of<ReportController>(
        context,
        listen: false,
      );
      // Check if we should navigate to Equary Calls tab (after call save)
      reportController.checkNavigationFlag();
      reportController.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HeaderController, ReportController>(
      builder: (context, headerController, reportController, child) {
        final currentCallList = reportController.getFilteredLeads();
        final tabs = [
          "All Calls",
          "Loss of Sale",
          "Feedback Calls",
          "Just Dial",
          "Equary Calls",
        ];

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                userName: "Shafna",
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
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
              // Tabs with horizontal scrolling
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final isSelected =
                        reportController.selectedCallTypeIndex == index;
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
                        child: Text(
                          tabs[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                            fontFamily: TextConstant.dmSansMedium,
                            color:
                                isSelected ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              // Show horizontal list for Just Dial, vertical list for others
              Expanded(
                child:
                    reportController.selectedCallTypeIndex == 3
                        ? _buildJustDialHorizontalList(
                          currentCallList,
                          reportController,
                        )
                        : currentCallList.isEmpty
                        ? Center(
                          child: Text(
                            reportController.selectedCallTypeIndex == 0
                                ? "No calls found"
                                : reportController.selectedCallTypeIndex == 1
                                ? "No loss of sale calls found"
                                : reportController.selectedCallTypeIndex == 2
                                ? "No feedback calls found"
                                : reportController.selectedCallTypeIndex == 3
                                ? "No Just Dial calls found"
                                : reportController.selectedCallTypeIndex == 4
                                ? "No enquiry calls found"
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
                              case "hardout": // Used for Feedback Calls (Rent out)
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
                                // Navigate to report details screen
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
                                      color: Colors.black.withOpacity(0.03),
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

  Widget _buildJustDialHorizontalList(
    List<Map<String, dynamic>> callList,
    ReportController reportController,
  ) {
    if (callList.isEmpty) {
      return Center(
        child: Text(
          "No Just Dial calls found",
          style: TextStyle(
            fontFamily: TextConstant.dmSansRegular,
            fontSize: 14,
            color: ColorConstant.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: callList.length,
      itemBuilder: (context, index) {
        final contact = callList[index];
        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JustDialDetailsScreen(contact: contact),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8D5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.headset_mic_outlined,
                          color: Color(0xFFF37927),
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    contact["name"] ?? "",
                    style: const TextStyle(
                      fontFamily: TextConstant.dmSansMedium,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contact["phone"] ?? "",
                    style: TextStyle(
                      fontFamily: TextConstant.dmSansRegular,
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        contact["date"] ?? "",
                        style: TextStyle(
                          fontFamily: TextConstant.dmSansRegular,
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  if (contact["storeName"] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.store, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            contact["storeName"] ?? "",
                            style: TextStyle(
                              fontFamily: TextConstant.dmSansRegular,
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
