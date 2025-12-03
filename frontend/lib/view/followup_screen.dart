import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/followup_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/store_location.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/view/reports_screens/report_screen.dart';

class FollowupScreen extends StatelessWidget {
  const FollowupScreen({super.key});

  final List<String> categories = const [
    "All",
    "Loss of Sales",
    "Rent out",
    "Booking confirmation",
    "Just Dial",
    "Follow Up",
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FollowupController>(context);
    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 62, right: 16, left: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedStore,
                        isExpanded: true,
                        dropdownColor: ColorConstant.primaryColor,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        hint: const Text(
                          "Select Store",
                          style: TextStyle(color: Colors.white70),
                        ),
                        items:
                            StoreLocations.buildStoreOptions().map((
                              String store,
                            ) {
                              return DropdownMenuItem<String>(
                                value: store,
                                child: Text(
                                  store,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          controller.setSelectedStore(newValue);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: const Text(
                        "Category",
                        style: TextStyle(color: Colors.white70),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                      dropdownColor: ColorConstant.primaryColor,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      items:
                          (categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          })).toList(),
                      value: controller.selectedCategory,
                      onChanged: (String? newValue) {
                        controller.setSelectedCategory(newValue);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Header with back button and title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // GestureDetector(
                          //   onTap:
                          //       () => Navigator.pop(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (context) => const ReportScreen(),
                          //         ),
                          //       ),
                          //   child: const Icon(
                          //     Icons.arrow_back_ios_outlined,
                          //     size: 18,
                          //   ),
                          // ),
                          Expanded(
                            child: Text(
                              "Follow-Up Calls",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: TextConstant.dmSansMedium,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                        ],
                      ),
                    ),

                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: ColorConstant.primaryColor.withOpacity(0.2),
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      child: CustomPaint(painter: DottedLinePainter()),
                    ),
                    const SizedBox(height: 16),
                    // Filter tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildTab(
                            context,
                            controller,
                            "Today",
                            0,
                            Icons.calendar_today,
                            controller.selectedTabIndex == 0,
                          ),
                          const SizedBox(width: 8),
                          _buildTab(
                            context,
                            controller,
                            "Upcoming",
                            1,
                            null,
                            controller.selectedTabIndex == 1,
                          ),
                          const SizedBox(width: 8),
                          _buildTab(
                            context,
                            controller,
                            "Overdue",
                            2,
                            null,
                            controller.selectedTabIndex == 2,
                            badgeCount: controller.overdueCount,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // List of follow-up calls
                    Expanded(child: _buildCallsList(context, controller)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    FollowupController controller,
    String label,
    int index,
    IconData? icon,
    bool isActive, {
    int? badgeCount,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.setSelectedTabIndex(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE8E3FF) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isActive
                      ? const Color(0xFF7C5DFF)
                      : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? const Color(0xFF7C5DFF) : Colors.grey,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: TextConstant.dmSansMedium,
                  color: isActive ? const Color(0xFF7C5DFF) : Colors.grey,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF7C5DFF),
                ),
              ],
              if (badgeCount != null && !isActive) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE23434),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallsList(BuildContext context, FollowupController controller) {
    final currentLeads = controller.getCurrentLeads();

    if (currentLeads.isEmpty) {
      return Center(
        child: Text(
          "No follow-up calls",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontFamily: TextConstant.dmSansRegular,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: currentLeads.length,
      itemBuilder: (context, index) {
        final lead = currentLeads[index];
        final call = controller.leadToDisplayMap(lead);
        return _buildCallItem(call);
      },
    );
  }

  Widget _buildCallItem(Map<String, dynamic> call) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: call["borderColor"] as Color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: call["iconBgColor"] as Color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                call["icon"] as IconData,
                color: call["iconColor"] as Color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Name, phone, and reason
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call["name"] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: TextConstant.dmSansMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    call["phone"] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: TextConstant.dmSansRegular,
                      color: const Color(0xff797979),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Reason: ${call["reason"] as String}",
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: TextConstant.dmSansRegular,
                      color: const Color(0xff797979),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: call["tagBgColor"] as Color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                call["tag"] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: TextConstant.dmSansMedium,
                  color: call["tagColor"] as Color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for dotted line
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = ColorConstant.primaryColor.withOpacity(0.2)
          ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
