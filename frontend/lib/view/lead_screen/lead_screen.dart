import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';
import 'package:telecaller_app/model/store_model.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/navigation_helper.dart';
import 'package:telecaller_app/widgets.dart/app_header.dart';
import 'package:telecaller_app/view/profile_screen.dart';

class LeadScreen extends StatefulWidget {
  const LeadScreen({super.key});

  @override
  State<LeadScreen> createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> {
  // Tab indices constants
  static const int _tabIndexBookingConfirmation = 0;
  static const int _tabIndexReturn = 1;

  // Initialization delay to allow UI to settle
  static const Duration _initializationDelay = Duration(milliseconds: 500);

  bool _isLoadingBookingConfirmation = false;
  bool _isLoadingReturn = false;

  @override
  void initState() {
    super.initState();

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

      Future.delayed(_initializationDelay, () {
        // Fetch Booking Confirmation and Feedback Calls
        _fetchBookingConfirmationLeads(leadController, headerController);
        _fetchReturnLeads(leadController, headerController);
      });
    });
  }

  /// Helper method to normalize store parameter (null if "All Stores")
  String? _getStoreParam(Store? store) {
    return (store == null || store.normalizedName == 'All Stores')
        ? null
        : store.normalizedName;
  }

  // ====================== FETCH FUNCTIONS ======================

  Future<void> _fetchBookingConfirmationLeads(
    LeadScreenController controller,
    HeaderController headerController,
  ) async {
    if (_isLoadingBookingConfirmation) return;

    setState(() => _isLoadingBookingConfirmation = true);

    try {
      final storeParam = _getStoreParam(headerController.selectedStore);
      await controller.fetchBookingConfirmationLeadsFromApi(store: storeParam);

      if (mounted) {
        controller.refresh();
        setState(() {});
      }
    } catch (e) {
      if (mounted &&
          controller.selectedCallTypeIndex == _tabIndexBookingConfirmation) {
        _showError("Failed to load Booking Confirmation calls", e);
      }
    } finally {
      if (mounted) setState(() => _isLoadingBookingConfirmation = false);
    }
  }

  Future<void> _fetchReturnLeads(
    LeadScreenController controller,
    HeaderController headerController,
  ) async {
    if (_isLoadingReturn) return;

    setState(() => _isLoadingReturn = true);

    try {
      final storeParam = _getStoreParam(headerController.selectedStore);

      // Format date parameters
      String? dateFrom;
      String? dateTo;

      if (headerController.isRangeMode &&
          headerController.dateRangeStart != null &&
          headerController.dateRangeEnd != null) {
        dateFrom = _formatDateForApi(headerController.dateRangeStart!);
        final endOfDay = DateTime(
          headerController.dateRangeEnd!.year,
          headerController.dateRangeEnd!.month,
          headerController.dateRangeEnd!.day,
          23,
          59,
          59,
        );
        dateTo = _formatDateForApi(endOfDay);
      } else {
        final selectedDate = headerController.selectedDate;
        dateFrom = _formatDateForApi(selectedDate);
        final endOfDay = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          23,
          59,
          59,
        );
        dateTo = _formatDateForApi(endOfDay);
      }

      print('═══════════════════════════════════════════════════════════');
      print('LeadScreen: FETCHING FEEDBACK CALLS');
      print('═══════════════════════════════════════════════════════════');
      print('Store: $storeParam');
      print('Date From: $dateFrom');
      print('Date To: $dateTo');
      print('Date Range Mode: ${headerController.isRangeMode}');
      print('Selected Date: ${headerController.selectedDate}');
      print('═══════════════════════════════════════════════════════════');

      await controller.fetchReturnLeadsFromApi(
        store: storeParam,
        fromDate: dateFrom,
        toDate: dateTo,
      );

      if (mounted) {
        controller.refresh();
        setState(() {});
      }
    } catch (e) {
      if (mounted && controller.selectedCallTypeIndex == _tabIndexReturn) {
        _showError("Failed to load Feedback calls", e);
      }
    } finally {
      if (mounted) setState(() => _isLoadingReturn = false);
    }
  }

  void _showError(String title, dynamic e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: ${e.toString().replaceAll("Exception: ", "")}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // =============================================================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final headerController = Provider.of<HeaderController>(
        context,
        listen: false,
      );
      final leadController = Provider.of<LeadScreenController>(
        context,
        listen: false,
      );

      leadController.refresh();

      if (!_isLoadingBookingConfirmation) {
        _fetchBookingConfirmationLeads(leadController, headerController);
      }
      if (!_isLoadingReturn) {
        _fetchReturnLeads(leadController, headerController);
      }
    });
  }

  /// Helper method to check if a category is currently loading
  bool _isLoadingCategory(int selectedIndex) {
    return (_isLoadingBookingConfirmation &&
            selectedIndex == _tabIndexBookingConfirmation) ||
        (_isLoadingReturn && selectedIndex == _tabIndexReturn);
  }

  // ============================ UI =============================

  @override
  Widget build(BuildContext context) {
    return Consumer2<HeaderController, LeadScreenController>(
      builder: (context, headerController, controller, child) {
        final filteredLeads = controller.getFilteredLeads();

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              AppHeader(
                onNotificationTap: () {},
                onProfileTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),

              // ==================== Tabs ====================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Booking Confirmation Tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          controller.setSelectedCallTypeIndex(
                            _tabIndexBookingConfirmation,
                          );
                          _fetchBookingConfirmationLeads(
                            controller,
                            headerController,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                controller.selectedCallTypeIndex ==
                                        _tabIndexBookingConfirmation
                                    ? ColorConstant.primaryColor
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  controller.selectedCallTypeIndex ==
                                          _tabIndexBookingConfirmation
                                      ? ColorConstant.primaryColor
                                      : Colors.grey[300]!,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "Booking Confirmation (${controller.getBookingConfirmationCount()})",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: TextConstant.dmSansMedium,
                                color:
                                    controller.selectedCallTypeIndex ==
                                            _tabIndexBookingConfirmation
                                        ? Colors.white
                                        : const Color(0xFFFFA500),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Feedback Calls Tab
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          controller.setSelectedCallTypeIndex(_tabIndexReturn);
                          _fetchReturnLeads(controller, headerController);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                controller.selectedCallTypeIndex ==
                                        _tabIndexReturn
                                    ? ColorConstant.primaryColor
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  controller.selectedCallTypeIndex ==
                                          _tabIndexReturn
                                      ? ColorConstant.primaryColor
                                      : Colors.grey[300]!,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "Feedback Calls (${filteredLeads.length})",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: TextConstant.dmSansMedium,
                                color:
                                    controller.selectedCallTypeIndex ==
                                            _tabIndexReturn
                                        ? Colors.white
                                        : const Color(0xFFFFA500),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================== Lead List ====================
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final headerController = Provider.of<HeaderController>(
                      context,
                      listen: false,
                    );

                    if (controller.selectedCallTypeIndex ==
                        _tabIndexBookingConfirmation) {
                      await _fetchBookingConfirmationLeads(
                        controller,
                        headerController,
                      );
                    } else if (controller.selectedCallTypeIndex ==
                        _tabIndexReturn) {
                      await _fetchReturnLeads(controller, headerController);
                    }
                  },
                  child:
                      _isLoadingCategory(controller.selectedCallTypeIndex)
                          ? const Center(child: CircularProgressIndicator())
                          : filteredLeads.isEmpty
                          ? _buildEmptyList(controller)
                          : _buildLeadList(filteredLeads),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Empty state UI
  Widget _buildEmptyList(LeadScreenController controller) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            children: [
              Text(
                "No leads found",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: TextConstant.dmSansRegular,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  final headerController = Provider.of<HeaderController>(
                    context,
                    listen: false,
                  );

                  if (controller.selectedCallTypeIndex ==
                      _tabIndexBookingConfirmation) {
                    _fetchBookingConfirmationLeads(
                      controller,
                      headerController,
                    );
                  } else if (controller.selectedCallTypeIndex ==
                      _tabIndexReturn) {
                    _fetchReturnLeads(controller, headerController);
                  }
                },
                child: const Text('Tap to refresh'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Lead list builder
  Widget _buildLeadList(List filteredLeads) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredLeads.length,
      itemBuilder: (context, index) {
        final lead = filteredLeads[index];
        return LeadListItem(
          lead: lead.toMap(),
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
    );
  }

  /// Format DateTime to API date string (YYYY-MM-DD)
  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ==================== Lead List Item Widget ====================

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
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Icon on left (speech bubble with heart)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ColorConstant.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: ColorConstant.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Customer information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead["name"] as String? ?? "N/A",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lead["phone"] as String? ?? "N/A",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: TextConstant.dmSansRegular,
                      ),
                    ),
                  ],
                ),
              ),
              // Date on right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lead["date"] as String? ?? "N/A",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontFamily: TextConstant.dmSansRegular,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
