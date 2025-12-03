import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/navigation_helper.dart';
import 'package:telecaller_app/widgets.dart/app_header.dart';
import 'package:telecaller_app/widgets.dart/call_summary_card.dart';

class LeadScreen extends StatefulWidget {
  const LeadScreen({super.key});

  @override
  State<LeadScreen> createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize controller with header controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final headerController = Provider.of<HeaderController>(
        context,
        listen: false,
      );
      final leadController = Provider.of<LeadScreenController>(
        context,
        listen: false,
      );
      leadController.init(headerController);
      leadController.refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible to show updated leads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leadController = Provider.of<LeadScreenController>(
        context,
        listen: false,
      );
      leadController.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HeaderController, LeadScreenController>(
      builder: (context, headerController, controller, child) {
        final callSummary = controller.getCallSummary();
        final filteredLeads = controller.getFilteredLeads();
        final currentTitle = controller.getCurrentTitle();

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Header Section
              AppHeader(
                userName: "Shafna",
                onNotificationTap: () {
                  // Handle notification tap
                },
              ),

              // Call Summary Cards - Horizontal Scrollable
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: callSummary.length,
                    itemBuilder: (context, index) {
                      final item = callSummary[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          width: 80,
                          child: CallSummaryCard(
                            title: item["title"],
                            count: item["count"],
                            bgColor: item["bgColor"],
                            iconColor: item["iconColor"],
                            icon: item["icon"],
                            isSelected:
                                controller.selectedCallTypeIndex == index,
                            onTap: () {
                              controller.setSelectedCallTypeIndex(index);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // All Calls List Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            callSummary[controller
                                    .selectedCallTypeIndex]["bgColor"]
                                as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${filteredLeads.length} Leads",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              callSummary[controller
                                      .selectedCallTypeIndex]["iconColor"]
                                  as Color,
                          fontFamily: TextConstant.dmSansMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Leads List
              Expanded(
                child:
                    filteredLeads.isEmpty
                        ? Center(
                          child: Text(
                            "No leads found",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: TextConstant.dmSansRegular,
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredLeads.length,
                          itemBuilder: (context, index) {
                            final lead = filteredLeads[index];
                            return LeadListItem(
                              lead:
                                  lead.toMap(), // Convert to map for backward compatibility
                              onTap: () {
                                if (lead.leadModel != null) {
                                  NavigationHelper.navigateToDetails(
                                    context,
                                    lead.leadModel!,
                                    lead.date,
                                  );
                                }
                              },
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

// Lead List Item Widget
class LeadListItem extends StatelessWidget {
  final Map<String, dynamic> lead;
  final VoidCallback? onTap;

  const LeadListItem({super.key, required this.lead, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
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
            horizontal: 12,
            vertical: 8,
          ),
          leading: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: lead["bgColor"] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              lead["icon"] as IconData,
              color: lead["iconColor"] as Color,
              size: 24,
            ),
          ),
          title: Text(
            lead["name"] as String,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              lead["phone"] as String,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                lead["date"] as String,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 4),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
