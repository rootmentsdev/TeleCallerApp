import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/store_location.dart';

class AppHeader extends StatelessWidget {
  final String userName;
  final bool showFilters;
  final bool showDate;
  final bool fullWidthStore;
  final VoidCallback? onNotificationTap;

  const AppHeader({
    super.key,
    required this.userName,
    this.showFilters = true,
    this.showDate = true,
    this.fullWidthStore = false,
    this.onNotificationTap,
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
                  CircleAvatar(
                    maxRadius: 20,
                    backgroundImage: AssetImage(
                      'assets/images/Screenshot 2025-11-27 174648.png',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome Back!",
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onNotificationTap,
                    child: Container(
                      height: 20,
                      width: 20,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                      ),
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
                          value:
                              headerController.selectedStore ==
                                      StoreLocations.allStoresLabel
                                  ? null
                                  : headerController.selectedStore,
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
                            headerController.setSelectedStore(newValue);
                          },
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      // Store Dropdown
                      Container(
                        height: 50,
                        width: showDate ? 200 : null,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value:
                                        headerController.selectedStore ==
                                                StoreLocations.allStoresLabel
                                            ? null
                                            : headerController.selectedStore,
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
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (String? newValue) {
                                      headerController.setSelectedStore(
                                        newValue,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showDate) ...[
                        const SizedBox(width: 16),
                        // Date Picker
                        InkWell(
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: headerController.selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              headerController.setSelectedDate(pickedDate);
                            }
                          },
                          child: Container(
                            height: 50,
                            width: 128,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      "Date",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                  ),
                                ],
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
