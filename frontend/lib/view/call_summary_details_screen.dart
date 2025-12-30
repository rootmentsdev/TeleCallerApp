import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/store_location.dart';
import 'package:telecaller_app/utils/navigation_helper.dart';
import 'package:telecaller_app/utils/format_helper.dart';

class CallSummaryDetailsScreen extends StatelessWidget {
  final String title;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final String callType; // 'all', 'loss', 'return', 'booking', 'justdial'

  const CallSummaryDetailsScreen({
    super.key,
    required this.title,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
    required this.callType,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<HeaderController, LeadRepository>(
      builder: (context, headerController, repository, child) {
        final date = headerController.selectedDate ?? DateTime.now();
        final store = headerController.selectedStore;

        // Get store location filter
        final storeFilter =
            (store == null || store == 'All Stores')
                ? null
                : StoreLocations.resolveSelection(store).location;

        // Get leads based on date
        List<dynamic> leads = repository.getLeadsByDate(date);

        // Filter by store
        if (storeFilter != null) {
          leads = leads.where((lead) => lead.location == storeFilter).toList();
        }

        // Filter by category based on callType
        leads =
            leads.where((lead) {
              final category = lead.category ?? '';
              switch (callType) {
                case 'all':
                  return true;
                case 'loss':
                  return category.toLowerCase().contains('loss');
                case 'return':
                  return category.toLowerCase().contains('rent') ||
                      category.toLowerCase().contains('return');
                case 'booking':
                  return category.toLowerCase().contains('booking');
                case 'justdial':
                  return category.toLowerCase().contains('justdial') ||
                      category.toLowerCase().contains('just dial');
                default:
                  return false;
              }
            }).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: ColorConstant.primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: TextConstant.dmSansMedium,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // List Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
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
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${leads.length} Leads",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                          fontFamily: TextConstant.dmSansMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Leads List
              Expanded(
                child:
                    leads.isEmpty
                        ? Center(
                          child: Text(
                            "No leads found",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontFamily: TextConstant.dmSansRegular,
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: leads.length,
                          itemBuilder: (context, index) {
                            final lead = leads[index];

                            return InkWell(
                              onTap: () {
                                NavigationHelper.navigateToDetails(
                                  context,
                                  lead,
                                  _formatDate(lead.createdAt),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
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
                                      color: bgColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: iconColor,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    lead.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      fontFamily: TextConstant.dmSansMedium,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lead.phone,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            fontFamily:
                                                TextConstant.dmSansRegular,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatDate(lead.createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                            fontFamily:
                                                TextConstant.dmSansRegular,
                                          ),
                                        ),
                                        if (lead.callDuration != null &&
                                            lead.callDuration! > 0) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            "Duration: ${FormatHelper.formatCallDurationWithUnits(lead.callDuration)}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green[700],
                                              fontFamily:
                                                  TextConstant.dmSansMedium,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.grey[400],
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${date.day} ${months[date.month - 1]}, ${date.year}";
  }
}
