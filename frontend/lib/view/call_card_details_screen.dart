import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/store_location.dart';

class CallCardDetailsScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String count;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;

  const CallCardDetailsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
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

        // Get leads based on call status (title)
        List<dynamic> leads = repository.getLeadsByDate(date);

        // Filter by store
        if (storeFilter != null) {
          leads = leads.where((lead) => lead.location == storeFilter).toList();
        }

        // Filter by call status based on title
        leads =
            leads.where((lead) {
              final callStatus = lead.callStatus ?? '';
              switch (title) {
                case 'Connected Calls':
                  return callStatus.toLowerCase().contains('connected');
                case 'Not Connected':
                  return callStatus.toLowerCase().contains('not connected');
                case 'Call Back Later':
                  return callStatus.toLowerCase().contains('call back');
                case 'Confirmed / Converted':
                  return callStatus.toLowerCase().contains('confirmed');
                case 'Cancelled / Rejected':
                  return callStatus.toLowerCase().contains('cancelled') ||
                      callStatus.toLowerCase().contains('rejected');
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
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ColorConstant.primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: iconColor, size: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontFamily: TextConstant.dmSansRegular,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      leads.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Call Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                    Text(
                      "Total: ${leads.length}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: TextConstant.dmSansRegular,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Call Details List
              Expanded(
                child:
                    leads.isEmpty
                        ? Center(
                          child: Text(
                            "No calls found",
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
                            final dateStr =
                                "${lead.createdAt.day} ${months[lead.createdAt.month - 1]}, ${lead.createdAt.year}";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
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
                                  child: Icon(icon, color: iconColor, size: 24),
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
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                          fontFamily:
                                              TextConstant.dmSansRegular,
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
