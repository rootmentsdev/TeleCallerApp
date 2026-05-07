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
import 'package:telecaller_app/view/lead_screen/justdial_detail_screen.dart';

class LeadScreen extends StatefulWidget {
  const LeadScreen({super.key});

  @override
  State<LeadScreen> createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> {
  // Tab indices constants
  static const int _tabIndexBookingConfirmation = 0;
  static const int _tabIndexReturn = 1;
  static const int _tabIndexJustDial = 2;

  // Initialization delay to allow UI to settle
  static const Duration _initializationDelay = Duration(milliseconds: 500);

  bool _isLoadingBookingConfirmation = false;
  bool _isLoadingReturn = false;
  bool _isLoadingJustDial = false;

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

      // Add listener to header controller for auto-refresh on store/date changes
      headerController.addListener(_onHeaderChanged);

      leadController.refresh();

      Future.delayed(_initializationDelay, () {
        // Fetch Booking Confirmation and Feedback Calls
        _fetchBookingConfirmationLeads(leadController, headerController);
        _fetchReturnLeads(leadController, headerController);
        _fetchJustDialLeads(leadController, headerController);
      });
    });
  }

  /// Called when header controller changes (store or date filter)
  void _onHeaderChanged() {
    final leadController = Provider.of<LeadScreenController>(
      context,
      listen: false,
    );
    final headerController = Provider.of<HeaderController>(
      context,
      listen: false,
    );

    // Refresh the currently selected tab
    if (leadController.selectedCallTypeIndex == _tabIndexBookingConfirmation) {
      _fetchBookingConfirmationLeads(leadController, headerController);
    } else if (leadController.selectedCallTypeIndex == _tabIndexReturn) {
      _fetchReturnLeads(leadController, headerController);
    } else if (leadController.selectedCallTypeIndex == _tabIndexJustDial) {
      _fetchJustDialLeads(leadController, headerController);
    }
  }

  @override
  void dispose() {
    // Remove listener when screen is disposed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final headerController = Provider.of<HeaderController>(
          context,
          listen: false,
        );
        headerController.removeListener(_onHeaderChanged);
      } catch (e) {
        // Context may not be available during dispose
      }
    });
    super.dispose();
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

      String? dateFrom;
      String? dateTo;
      if (headerController.isRangeMode &&
          headerController.dateRangeStart != null &&
          headerController.dateRangeEnd != null) {
        dateFrom = _formatDateForApi(headerController.dateRangeStart!);
        dateTo = _formatDateForApi(
          DateTime(
            headerController.dateRangeEnd!.year,
            headerController.dateRangeEnd!.month,
            headerController.dateRangeEnd!.day,
            23,
            59,
            59,
          ),
        );
      } else {
        final d = headerController.selectedDate;
        dateFrom = _formatDateForApi(d);
        dateTo = _formatDateForApi(
          DateTime(d.year, d.month, d.day, 23, 59, 59),
        );
      }

      await controller.fetchBookingConfirmationLeadsFromApi(
        store: storeParam,
        fromDate: dateFrom,
        toDate: dateTo,
      );

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

  Future<void> _fetchJustDialLeads(
    LeadScreenController controller,
    HeaderController headerController,
  ) async {
    if (_isLoadingJustDial) return;

    setState(() => _isLoadingJustDial = true);

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

      await controller.fetchJustDialLeadsFromApi(
        store: storeParam,
        fromDate: dateFrom,
        toDate: dateTo,
      );

      if (mounted) {
        controller.refresh();
        setState(() {});
      }
    } catch (e) {
      if (mounted && controller.selectedCallTypeIndex == _tabIndexJustDial) {
        _showError("Failed to load JustDial leads", e);
      }
    } finally {
      if (mounted) setState(() => _isLoadingJustDial = false);
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

  /// Helper method to check if a category is currently loading
  bool _isLoadingCategory(int selectedIndex) {
    return (_isLoadingBookingConfirmation &&
            selectedIndex == _tabIndexBookingConfirmation) ||
        (_isLoadingReturn && selectedIndex == _tabIndexReturn) ||
        (_isLoadingJustDial && selectedIndex == _tabIndexJustDial);
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

              // ==================== Category Cards ====================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCategoryCard(
                      icon: Icons.message,
                      label: "Feedback\nCalls",
                      count: controller.getReturnLeadsCount(),
                      isSelected:
                          controller.selectedCallTypeIndex == _tabIndexReturn,
                      onTap: () {
                        controller.setSelectedCallTypeIndex(_tabIndexReturn);
                        _fetchReturnLeads(controller, headerController);
                      },
                    ),
                    _buildCategoryCard(
                      icon: Icons.local_shipping_outlined,
                      label: "Booking\nConfirmation",
                      count: controller.getBookingConfirmationCount(),
                      isSelected:
                          controller.selectedCallTypeIndex ==
                          _tabIndexBookingConfirmation,
                      onTap: () {
                        controller.setSelectedCallTypeIndex(
                          _tabIndexBookingConfirmation,
                        );
                        _fetchBookingConfirmationLeads(
                          controller,
                          headerController,
                        );
                      },
                    ),
                    _buildCategoryCard(
                      icon: Icons.headphones_outlined,
                      label: "Just Dial",
                      count: controller.getJustDialLeadsCount(),
                      isSelected:
                          controller.selectedCallTypeIndex == _tabIndexJustDial,
                      onTap: () {
                        controller.setSelectedCallTypeIndex(_tabIndexJustDial);
                      },
                    ),
                  ],
                ),
              ),

              // ==================== Section Title ====================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.selectedCallTypeIndex == _tabIndexReturn
                          ? "Feedback Calls"
                          : controller.selectedCallTypeIndex ==
                              _tabIndexJustDial
                          ? "Just Dial"
                          : "Booking Confirmation Calls",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7CC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${filteredLeads.length} Calls",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFCC00),
                          fontFamily: TextConstant.dmSansMedium,
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

  Widget _buildCategoryCard({
    required IconData icon,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? ColorConstant.primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : ColorConstant.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: TextConstant.dmSansMedium,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontFamily: TextConstant.dmSansRegular,
              ),
            ),
          ),
        ],
      ),
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
              // Navigate to appropriate detail screen based on category
              if (lead.leadModel!.category == 'Just Dial') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            JustDialDetailScreen(lead: lead.leadModel!),
                  ),
                );
              } else {
                NavigationHelper.navigateToDetails(
                  context,
                  lead.leadModel!,
                  lead.date,
                );
              }
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

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'feedback':
      case 'rentout':
      case 'rent out':
        return Icons.favorite_outline;
      case 'booking confirmation':
      case 'bookingconfirmation':
        return Icons.local_shipping_outlined;
      case 'just dial':
        return Icons.headphones_outlined;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  Color _getColorForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'feedback':
      case 'rentout':
      case 'rent out':
        return const Color(0xFFE91E63);
      case 'booking confirmation':
      case 'bookingconfirmation':
        return ColorConstant.primaryColor;
      case 'just dial':
        return ColorConstant.primaryColor;
      default:
        return ColorConstant.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = lead["category"] as String?;
    final icon = _getIconForCategory(category);
    final color = _getColorForCategory(category);

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
              // Icon on left (category-based)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
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
                      "+91 ${lead["phone"] as String? ?? "N/A"}",
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
