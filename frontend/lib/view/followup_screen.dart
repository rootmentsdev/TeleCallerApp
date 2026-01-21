import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/followup_controller.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/widgets.dart/app_header.dart';
import 'package:telecaller_app/view/profile_screen.dart';

class FollowupScreen extends StatefulWidget {
  const FollowupScreen({super.key});

  @override
  State<FollowupScreen> createState() => _FollowupScreenState();
}

class _FollowupScreenState extends State<FollowupScreen> {
  final List<String> categories = const [
    "All",
    "Loss of Sales",
    "Return",
    "Booking confirmation",
    "Just Dial",
    "Follow Up",
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controller with header controller and fetch follow-up leads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final headerController = Provider.of<HeaderController>(
        context,
        listen: false,
      );
      final followupController = Provider.of<FollowupController>(
        context,
        listen: false,
      );
      followupController.init(headerController);
      followupController.fetchFollowUpLeads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FollowupController>(context);

    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      body: Column(
        children: [
          AppHeader(
            showDate: true,
            showFilters: true,
            onNotificationTap: () {
              // Handle notification tap
            },
            onProfileTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
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
                    const SizedBox(height: 16),
                    // Filter tabs with counts
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterTab(
                              context,
                              controller,
                              "Overdue",
                              0,
                              controller.overdueCount,
                              controller.selectedTabIndex == 0,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterTab(
                              context,
                              controller,
                              "Today",
                              1,
                              controller.getCurrentLeads().length,
                              controller.selectedTabIndex == 1,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterTab(
                              context,
                              controller,
                              "Tomorrow",
                              2,
                              null,
                              controller.selectedTabIndex == 2,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterTab(
                              context,
                              controller,
                              "Upcor",
                              3,
                              null,
                              controller.selectedTabIndex == 3,
                            ),
                          ],
                        ),
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

  Widget _buildFilterTab(
    BuildContext context,
    FollowupController controller,
    String label,
    int index,
    int? count,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () {
        controller.setSelectedTabIndex(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0A2540) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF0A2540) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count != null ? "$label ($count)" : label,
              style: TextStyle(
                fontSize: 14,
                fontFamily: TextConstant.dmSansMedium,
                color: isActive ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallsList(BuildContext context, FollowupController controller) {
    // Show loading state
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading follow-up calls',
              style: TextStyle(
                fontFamily: TextConstant.dmSansMedium,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.error ?? '',
              style: TextStyle(
                fontFamily: TextConstant.dmSansRegular,
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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
        return _buildCallItem(call, context);
      },
    );
  }

  Widget _buildCallItem(Map<String, dynamic> call, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and Lead Type Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    call["name"] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: TextConstant.dmSansMedium,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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

            const SizedBox(height: 8),

            // Phone Number
            Text(
              call["phone"] as String,
              style: TextStyle(
                fontSize: 14,
                fontFamily: TextConstant.dmSansRegular,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 12),

            // Remarks / Notes
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Remarks / Notes",
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: TextConstant.dmSansRegular,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  call["reason"] as String? ?? "No remarks",
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: TextConstant.dmSansRegular,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Store and Date/Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    call["storeName"] as String? ?? "Store",
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: TextConstant.dmSansRegular,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Text(
                  call["followUpDate"] as String? ?? "Date",
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: TextConstant.dmSansRegular,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Call Now Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement call functionality
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstant.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Call Now",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: TextConstant.dmSansMedium,
                    fontWeight: FontWeight.w600,
                  ),
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
          ..color = ColorConstant.primaryColor.withValues(alpha: 0.2)
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
