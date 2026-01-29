import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/followup_controller.dart';
import 'package:telecaller_app/services/auth_service.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/store_location.dart';

class AppHeader extends StatelessWidget {
  final String? userName; // Made optional - will load from AuthService if null
  final bool showFilters;
  final bool showDate;
  final bool fullWidthStore;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const AppHeader({
    super.key,
    this.userName,
    this.showFilters = true,
    this.showDate = true,
    this.fullWidthStore = false,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final headerController = Provider.of<HeaderController>(context);

    return Container(
      decoration: BoxDecoration(
        color: ColorConstant.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Profile and Notification Row
              Row(
                children: [
                  InkWell(
                    onTap: onProfileTap,
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          maxRadius: 20,
                          backgroundImage: const AssetImage(
                            'assets/images/profile_icon.jpg',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Welcome Back!",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<String?>(
                                future: AuthService.getUserName(),
                                builder: (context, snapshot) {
                                  final displayName =
                                      userName ?? snapshot.data ?? 'User';
                                  return Text(
                                    displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onNotificationTap,
                    child: Stack(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white10,
                          ),
                          child: const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        // Notification badge
                        Consumer<FollowupController>(
                          builder: (context, followupController, _) {
                            // Get ALL follow-up leads (not filtered by selected date)
                            final allFollowUpLeads =
                                followupController.allFollowUpLeads;

                            // Filter for today's follow-ups only
                            final todayFollowUps =
                                allFollowUpLeads.where((lead) {
                                  if (lead.followUpDate == null) return false;
                                  final today = DateTime.now();
                                  final todayUtc = DateTime.utc(
                                    today.year,
                                    today.month,
                                    today.day,
                                  );
                                  final followUpUtc = DateTime.utc(
                                    lead.followUpDate!.year,
                                    lead.followUpDate!.month,
                                    lead.followUpDate!.day,
                                  );
                                  return followUpUtc.compareTo(todayUtc) == 0;
                                }).length;

                            if (todayFollowUps > 0) {
                              return Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                  ),
                                  child: Center(
                                    child: Text(
                                      todayFollowUps > 9
                                          ? '9+'
                                          : '$todayFollowUps',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showFilters) ...[
                const SizedBox(height: 16),
                // Store Dropdown and Date Picker Row
                if (fullWidthStore && !showDate)
                  // Full width store dropdown (for home screen)
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: headerController.selectedStore,
                          isExpanded: true,
                          dropdownColor: ColorConstant.primaryColor,
                          icon: const Icon(
                            Icons.arrow_drop_down,
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
                            if (newValue != null) {
                              headerController.setSelectedStore(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      // Store Dropdown
                      Expanded(
                        flex: showDate ? 1 : 2,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
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
                                          StoreLocations.buildStoreOptions()
                                              .map((String store) {
                                                return DropdownMenuItem<String>(
                                                  value: store,
                                                  child: Text(
                                                    store,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                );
                                              })
                                              .toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          headerController.setSelectedStore(
                                            newValue,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (showDate) ...[
                        const SizedBox(width: 12),
                        // Date Range Picker
                        Expanded(
                          flex: 1,
                          child: InkWell(
                            onTap: () async {
                              final DateTimeRange?
                              pickedRange = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                                currentDate: headerController.selectedDate,
                                initialDateRange:
                                    headerController.isRangeMode
                                        ? DateTimeRange(
                                          start:
                                              headerController.dateRangeStart ??
                                              DateTime.now(),
                                          end:
                                              headerController.dateRangeEnd ??
                                              DateTime.now(),
                                        )
                                        : null,
                              );
                              if (pickedRange != null) {
                                headerController.setDateRange(
                                  pickedRange.start,
                                  pickedRange.end,
                                );
                              }
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        headerController.isRangeMode
                                            ? '${headerController.dateRangeStart?.day}/${headerController.dateRangeStart?.month} - ${headerController.dateRangeEnd?.day}/${headerController.dateRangeEnd?.month}'
                                            : '${headerController.selectedDate.day}/${headerController.selectedDate.month}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
