import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/followup_controller.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/view/followup_screen/followup_detail_screen.dart';
import 'package:telecaller_app/model/lead_model.dart';

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
      print('FollowupScreen: initState - fetchFollowUpLeads called');
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<FollowupController>(context);

    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      body: Column(
        children: [
          // Custom Header matching the image
          Container(
            color: ColorConstant.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // Placeholder for alignment
                const Text(
                  "Follow Ups",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Handle notification tap
                  },
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
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
                              controller.todayCount,
                              controller.selectedTabIndex == 1,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterTab(
                              context,
                              controller,
                              "Tomorrow",
                              2,
                              controller.tomorrowCount,
                              controller.selectedTabIndex == 2,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterTab(
                              context,
                              controller,
                              "Upcoming",
                              3,
                              controller.upcomingCount,
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
        print('FollowupScreen: Tab $index ($label) tapped');
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

    print(
      'FollowupScreen: _buildCallsList called - currentLeads.length=${currentLeads.length}, selectedTab=${controller.selectedTabIndex}',
    );

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: currentLeads.length,
      itemBuilder: (context, index) {
        final lead = currentLeads[index];
        final call = controller.leadToDisplayMap(lead);
        return _buildCallItem(call, lead, context);
      },
    );
  }

  Widget _buildCallItem(
    Map<String, dynamic> call,
    LeadModel lead,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to follow-up detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowupDetailScreen(lead: lead),
          ),
        );
      },
      child: Container(
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
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatLeadType(call["leadType"]),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: TextConstant.dmSansMedium,
                        color: Color(0xFF1976D2),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                    _formatFollowUpDate(call["followUpDate"]),
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: TextConstant.dmSansRegular,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format follow-up date - handles both DateTime and String types
  String _formatFollowUpDate(dynamic date) {
    if (date == null) return "Date";

    try {
      if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (date is String) {
        final parsed = DateTime.parse(date);
        return '${parsed.day}/${parsed.month}/${parsed.year}';
      }
    } catch (e) {
      return "Date";
    }

    return "Date";
  }

  /// Format lead type for display - converts 'booked' to 'Booked', etc.
  String _formatLeadType(dynamic leadType) {
    if (leadType == null) return "Lead";

    final type = leadType.toString().toLowerCase();
    switch (type) {
      case 'enquiry':
        return 'Enquiry';
      case 'booked':
      case 'booking':
        return 'Booked';
      case 'return':
      case 'hardout':
        return 'Feedback';
      case 'bookingconfirmation':
      case 'booking confirmation':
        return 'Booking Confirmation';
      default:
        return leadType.toString();
    }
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
