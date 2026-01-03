import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/followup_controller.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/view/details_screen.dart';
import 'package:telecaller_app/widgets.dart/app_header.dart';

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
              // if (isActive) ...[
              //   const SizedBox(width: 6),
              //   const Icon(
              //     Icons.keyboard_arrow_down,
              //     size: 16,
              //     color: Color(0xFF7C5DFF),
              //   ),
              // ],
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
    return GestureDetector(
      onTap: () {
        // Open details screen (editable view) when follow-up lead is clicked
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => DetailsScreen(
                  contact: call,
                  callTypeIndex: 0, // All Calls tab
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: call["borderColor"] as Color, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
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
