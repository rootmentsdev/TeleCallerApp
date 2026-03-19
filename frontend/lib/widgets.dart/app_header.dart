import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/model/store_model.dart';
import 'package:telecaller_app/services/auth_service.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:intl/intl.dart';

class AppHeader extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const AppHeader({super.key, this.onNotificationTap, this.onProfileTap});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await AuthService.getUserName();
    if (mounted && name != null) {
      setState(() => _userName = name.toUpperCase());
    }
  }

  Future<void> _showDateRangePicker(HeaderController headerController) async {
    final now = DateTime.now();
    final initialRange =
        headerController.isRangeMode &&
                headerController.dateRangeStart != null &&
                headerController.dateRangeEnd != null
            ? DateTimeRange(
              start: headerController.dateRangeStart!,
              end: headerController.dateRangeEnd!,
            )
            : DateTimeRange(
              start: headerController.selectedDate,
              end: headerController.selectedDate,
            );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.white,
              onPrimary: ColorConstant.primaryColor,
              surface: const Color(0xFF0D2D4A),
              onSurface: Colors.white,
              secondary: Colors.white24,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (picked.start == picked.end) {
        headerController.setSelectedDate(picked.start);
      } else {
        headerController.setDateRange(picked.start, picked.end);
      }
    }
  }

  String _formatDateLabel(HeaderController hc) {
    final fmt = DateFormat('d/M');
    if (hc.isRangeMode &&
        hc.dateRangeStart != null &&
        hc.dateRangeEnd != null) {
      return '${fmt.format(hc.dateRangeStart!)} - ${fmt.format(hc.dateRangeEnd!)}';
    }
    return fmt.format(hc.selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HeaderController>(
      builder: (context, headerController, _) {
        return Container(
          color: ColorConstant.primaryColor,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: profile + name + notification
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.phone_in_talk_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                        ),
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onNotificationTap,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3A5C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Bottom row: store dropdown + date picker
              Row(
                children: [
                  // Store dropdown
                  Expanded(
                    child: _FilterPill(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Store>(
                          value: headerController.selectedStore,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF0D2D4A),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: 20,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          hint: const Text(
                            'Select Store',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          items: [
                            DropdownMenuItem<Store>(
                              value: Store(
                                brand: 'All',
                                location: 'Stores',
                                normalizedName: 'All Stores',
                              ),
                              child: const Text(
                                'Select Store',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ...headerController.availableStores.map((store) {
                              return DropdownMenuItem<Store>(
                                value: store,
                                child: Text(
                                  store.normalizedName,
                                  style: const TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (Store? newValue) {
                            if (newValue != null) {
                              headerController.setSelectedStore(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Date picker pill
                  _FilterPill(
                    onTap: () => _showDateRangePicker(headerController),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateLabel(headerController),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _FilterPill({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2D4A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(child: child),
      ),
    );
  }
}
