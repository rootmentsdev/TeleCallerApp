import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/navigation_helper.dart';
import 'package:telecaller_app/widgets.dart/app_header.dart';
import 'package:telecaller_app/widgets.dart/call_summary_card.dart';
import 'package:telecaller_app/view/profile_screen.dart';

class LeadScreen extends StatefulWidget {
  const LeadScreen({super.key});

  @override
  State<LeadScreen> createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> {
  // Tab indices constants
  static const int _tabIndexLossOfSale = 1;
  static const int _tabIndexReturn = 2;
  static const int _tabIndexBookingConfirmation = 3;
  static const int _tabIndexStarred = 4;

  // Initialization delay to allow UI to settle
  static const Duration _initializationDelay = Duration(milliseconds: 500);

  bool _isLoadingLossOfSale = false;
  bool _isLoadingBookingConfirmation = false;
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
        // Fetch all leads with store and date filters for "All Calls" tab
        final storeParam = _getStoreParam(headerController.selectedStore);
        final selectedDate = headerController.selectedDate;

        if (storeParam != null) {
          leadController
              .fetchAllLeadsFromApi(store: storeParam, date: selectedDate)
              .catchError((e) {
                debugPrint('Error fetching all leads: $e');
              });
        } else {
          leadController.fetchAllLeadsFromApi(date: selectedDate).catchError((
            e,
          ) {
            debugPrint('Error fetching all leads: $e');
          });
        }

        // Fetch category-specific leads
        _fetchLossOfSaleLeads(leadController, headerController);
        _fetchBookingConfirmationLeads(leadController, headerController);
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

  Future<void> _fetchLossOfSaleLeads(
    LeadScreenController controller,
    HeaderController headerController,
  ) async {
    if (_isLoadingLossOfSale) return;

    setState(() => _isLoadingLossOfSale = true);

    try {
      final storeParam = _getStoreParam(headerController.selectedStore);
      await controller.fetchLossOfSaleLeadsFromApi(store: storeParam);

      if (mounted) {
        controller.refresh();
        setState(() {});
      }
    } catch (e) {
      if (mounted && controller.selectedCallTypeIndex == _tabIndexLossOfSale) {
        _showError("Failed to load Loss of Sale leads", e);
      }
    } finally {
      if (mounted) setState(() => _isLoadingLossOfSale = false);
    }
  }

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
        _showError("Failed to load Booking Confirmation leads", e);
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
      await controller.fetchReturnLeadsFromApi(store: storeParam);

      if (mounted) {
        controller.refresh();
        setState(() {});
      }
    } catch (e) {
      if (mounted && controller.selectedCallTypeIndex == _tabIndexReturn) {
        _showError("Failed to load Return leads", e);
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
        _showError("Failed to load Starred calls", e);
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

      if (!_isLoadingLossOfSale) {
        _fetchLossOfSaleLeads(leadController, headerController);
      }
      if (!_isLoadingBookingConfirmation) {
        _fetchBookingConfirmationLeads(leadController, headerController);
      }
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
    return (_isLoadingLossOfSale && selectedIndex == _tabIndexLossOfSale) ||
        (_isLoadingReturn && selectedIndex == _tabIndexReturn) ||
        (_isLoadingBookingConfirmation &&
            selectedIndex == _tabIndexBookingConfirmation) ||
        (_isLoadingStarred && selectedIndex == _tabIndexStarred);
  }

  /// Build lead count badge with safe type casting
  Widget _buildLeadCountBadge(Map<String, dynamic> summaryItem, int count) {
    final bgColor = summaryItem["bgColor"];
    final iconColor = summaryItem["iconColor"];

    if (bgColor is! Color || iconColor is! Color) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$count Leads",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: iconColor,
          fontFamily: TextConstant.dmSansMedium,
        ),
      ),
    );
  }

  // ============================ UI =============================

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

              // ================= Summary Cards =================
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 80,
                          child: CallSummaryCard(
                            title: item["title"],
                            count: item["count"],
                            bgColor: item["bgColor"],
                            iconColor: item["iconColor"],
                            icon: item["icon"],
                            context: context,
                            callType: item["callType"],
                            isSelected:
                                controller.selectedCallTypeIndex == index,
                            isStarred: item["isStarred"] ?? false,
                            onTap: () async {
                              controller.setSelectedCallTypeIndex(index);
                              final headerController =
                                  Provider.of<HeaderController>(
                                    context,
                                    listen: false,
                                  );

                              if (index == _tabIndexLossOfSale) {
                                await _fetchLossOfSaleLeads(
                                  controller,
                                  headerController,
                                );
                              } else if (index == _tabIndexReturn) {
                                await _fetchReturnLeads(
                                  controller,
                                  headerController,
                                );
                              } else if (index ==
                                  _tabIndexBookingConfirmation) {
                                await _fetchBookingConfirmationLeads(
                                  controller,
                                  headerController,
                                );
                              } else if (index == _tabIndexStarred) {
                                await _fetchStarredCalls(
                                  controller,
                                  headerController,
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ==================== List Header ====================
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
                    if (controller.selectedCallTypeIndex >= 0 &&
                        controller.selectedCallTypeIndex < callSummary.length)
                      _buildLeadCountBadge(
                        callSummary[controller.selectedCallTypeIndex],
                        filteredLeads.length,
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
                        _tabIndexLossOfSale) {
                      await _fetchLossOfSaleLeads(controller, headerController);
                    } else if (controller.selectedCallTypeIndex ==
                        _tabIndexReturn) {
                      await _fetchReturnLeads(controller, headerController);
                    } else if (controller.selectedCallTypeIndex ==
                        _tabIndexBookingConfirmation) {
                      await _fetchBookingConfirmationLeads(
                        controller,
                        headerController,
                      );
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

                  if (controller.selectedCallTypeIndex == _tabIndexLossOfSale) {
                    _fetchLossOfSaleLeads(controller, headerController);
                  } else if (controller.selectedCallTypeIndex ==
                      _tabIndexReturn) {
                    _fetchReturnLeads(controller, headerController);
                  } else if (controller.selectedCallTypeIndex ==
                      _tabIndexBookingConfirmation) {
                    _fetchBookingConfirmationLeads(
                      controller,
                      headerController,
                    );
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

  /// Build lead icon with safe type casting
  Widget _buildLeadIcon(Map<String, dynamic> lead) {
    final bgColor = lead["bgColor"];
    final icon = lead["icon"];
    final iconColor = lead["iconColor"];

    if (bgColor is! Color || icon is! IconData || iconColor is! Color) {
      return Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.person, size: 24, color: Colors.grey),
      );
    }

    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }

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
              color: Colors.black.withValues(alpha: 0.03),
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
          leading: _buildLeadIcon(lead),
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
