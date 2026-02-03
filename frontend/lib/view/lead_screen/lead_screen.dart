import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';
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
  static const int _tabIndexReturn = 0;
  static const int _tabIndexStarred = 1;

  // Initialization delay to allow UI to settle
  static const Duration _initializationDelay = Duration(milliseconds: 500);

  bool _isLoadingReturn = false;
  bool _isLoadingStarred = false;

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
        // Fetch only Feedback Calls and Marked Calls
        _fetchReturnLeads(leadController, headerController);
        _fetchStarredCalls(leadController, headerController);
      });
    });
  }

  /// Helper method to normalize store parameter (null if "All Stores")
  String? _getStoreParam(String? store) {
    return (store == null || store == 'All Stores') ? null : store;
  }

  // ====================== FETCH FUNCTIONS ======================

  Future<void> _fetchReturnLeads(
    LeadScreenController controller,
    HeaderController headerController,
  ) async {
    if (_isLoadingReturn) return;

    setState(() => _isLoadingReturn = true);

    try {
      final storeParam = _getStoreParam(headerController.selectedStore);
      await controller.fetchReturnLeadsFromApi(store: storeParam);

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

  Future<void> _fetchStarredCalls(
    LeadScreenController controller,
    HeaderController headerController,
  ) async {
    if (_isLoadingStarred) return;

    setState(() => _isLoadingStarred = true);

    try {
      final storeParam = _getStoreParam(headerController.selectedStore);
      await controller.fetchStarredCallsFromApi(store: storeParam);

      if (mounted) {
        controller.refresh();
        setState(() {});
      }
    } catch (e) {
      if (mounted && controller.selectedCallTypeIndex == _tabIndexStarred) {
        _showError("Failed to load Marked calls", e);
      }
    } finally {
      if (mounted) setState(() => _isLoadingStarred = false);
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

      if (!_isLoadingReturn) {
        _fetchReturnLeads(leadController, headerController);
      }
      if (!_isLoadingStarred) {
        _fetchStarredCalls(leadController, headerController);
      }
    });
  }

  /// Helper method to check if a category is currently loading
  bool _isLoadingCategory(int selectedIndex) {
    return (_isLoadingReturn && selectedIndex == _tabIndexReturn) ||
        (_isLoadingStarred && selectedIndex == _tabIndexStarred);
  }

  // ============================ UI =============================

  @override
  Widget build(BuildContext context) {
    return Consumer2<HeaderController, LeadScreenController>(
      builder: (context, headerController, controller, child) {
        final filteredLeads = controller.getFilteredLeads();
        final currentTitle = controller.getCurrentTitle();

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

              // ==================== List Header ====================
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: TextConstant.dmSansMedium,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "(${filteredLeads.length} Calls)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: TextConstant.dmSansMedium,
                        color: const Color(0xFFFFA500),
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

                    if (controller.selectedCallTypeIndex == _tabIndexReturn) {
                      await _fetchReturnLeads(controller, headerController);
                    } else if (controller.selectedCallTypeIndex ==
                        _tabIndexStarred) {
                      await _fetchStarredCalls(controller, headerController);
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

                  if (controller.selectedCallTypeIndex == _tabIndexReturn) {
                    _fetchReturnLeads(controller, headerController);
                  } else if (controller.selectedCallTypeIndex ==
                      _tabIndexStarred) {
                    _fetchStarredCalls(controller, headerController);
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead["name"] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorConstant.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lead["phone"] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ColorConstant.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          fontWeight: FontWeight.w600,
                          color: ColorConstant.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            lead["location"] as String? ?? "N/A",
                            style: TextStyle(
                              fontSize: 13,
                              color: ColorConstant.primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
