import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';
import 'package:telecaller_app/controller/report_controller.dart';
import 'package:telecaller_app/controller/complaints_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/model/lead_display_model.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/widgets.dart/app_header.dart';
import 'package:telecaller_app/widgets.dart/common_widgets.dart';
import 'package:telecaller_app/view/profile_screen.dart';
import 'package:telecaller_app/widgets.dart/add_lead_outgoing_call_bottom_sheet.dart';
import 'package:telecaller_app/view/home_screen/bottomnavigation_bar.dart';
import 'package:telecaller_app/view/complaints_screen/complaints_screen.dart';
import 'package:telecaller_app/view/followup_screen/followup_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingFollowUps = false;
  final LeadRepository _repository = LeadRepository();
  late ComplaintsController _complaintsController;

  @override
  void initState() {
    super.initState();

    // Initialize complaints controller
    _complaintsController = ComplaintsController();

    // Listen to repository changes to update UI when follow-ups are fetched
    _repository.addListener(_onRepositoryChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final headerController = Provider.of<HeaderController>(
        context,
        listen: false,
      );
      final leadController = Provider.of<LeadScreenController>(
        context,
        listen: false,
      );
      final reportController = Provider.of<ReportController>(
        context,
        listen: false,
      );

      leadController.init(headerController);
      leadController.refresh();

      reportController.init(headerController);
      reportController.fetchReportsWithCurrentFilters();

      Future.delayed(const Duration(milliseconds: 500), () {
        _fetchFollowUpLeads(headerController);
        _fetchComplaints(headerController);
      });
    });
  }

  void _onRepositoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    _complaintsController.dispose();
    super.dispose();
  }

  String? _getStoreParam(String? store) {
    return (store == null || store == 'All Stores') ? null : store;
  }

  Future<void> _fetchFollowUpLeads(HeaderController headerController) async {
    if (_isLoadingFollowUps) return;

    setState(() => _isLoadingFollowUps = true);

    try {
      final storeParam = _getStoreParam(headerController.selectedStore);
      // Fetch follow-up leads specifically from API
      await _repository.fetchFollowUpLeadsFromApi(store: storeParam);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('HomeScreen: Error fetching follow-ups: $e');
      // Don't show error notification on app load - silently handle the error
      // Only log it for debugging purposes
    } finally {
      if (mounted) {
        setState(() => _isLoadingFollowUps = false);
      }
    }
  }

  Future<void> _fetchComplaints(HeaderController headerController) async {
    try {
      final storeParam = _getStoreParam(headerController.selectedStore);
      final today = DateTime.now();
      final dateFrom =
          DateTime(today.year, today.month, today.day).toIso8601String();
      final dateTo =
          DateTime(
            today.year,
            today.month,
            today.day,
            23,
            59,
            59,
          ).toIso8601String();

      await _complaintsController.fetchComplaints(
        store: storeParam,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('HomeScreen: Error fetching complaints: $e');
      // Silently handle the error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<HeaderController, LeadScreenController, ReportController>(
      builder: (
        context,
        headerController,
        leadController,
        reportController,
        child,
      ) {
        // Get today's follow-ups directly from repository
        final todayFollowUpLeads =
            _repository.todayFollowUps
                .map((lead) => LeadDisplayModel.fromLead(lead))
                .toList();

        // Get total follow-up count (filtered by store if selected)
        final selectedStore = headerController.selectedStore;
        int totalFollowUpCount = _repository.followUpLeads.length;

        // Filter by store if a specific store is selected
        if (selectedStore != 'All Stores') {
          final storeLocation =
              selectedStore.contains(' - ')
                  ? selectedStore.split(' - ')[1].trim()
                  : selectedStore;
          totalFollowUpCount =
              _repository.followUpLeads
                  .where((lead) => lead.location == storeLocation)
                  .length;
        }

        // Get calls today count - calculate independently to avoid being overridden by reports screen
        // Count leads created today with call duration > 0 + complaint calls with duration > 0
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayEnd = DateTime(
          today.year,
          today.month,
          today.day,
          23,
          59,
          59,
        );

        // Filter by store if a specific store is selected
        // IMPORTANT: Exclude leads marked as complaints to avoid duplicate counting
        List<LeadModel> callsTodayLeads =
            _repository.allLeads
                .where(
                  (lead) =>
                      lead.createdAt.isAfter(todayStart) &&
                      lead.createdAt.isBefore(todayEnd) &&
                      (lead.callDuration ?? 0) > 0 &&
                      (lead.markAsComplaint !=
                          true), // Exclude complaint-marked leads
                )
                .toList();

        if (selectedStore != 'All Stores') {
          final storeLocation =
              selectedStore.contains(' - ')
                  ? selectedStore.split(' - ')[1].trim()
                  : selectedStore;
          callsTodayLeads =
              callsTodayLeads
                  .where(
                    (lead) =>
                        lead.location?.toLowerCase() ==
                        storeLocation.toLowerCase(),
                  )
                  .toList();
        }

        // Add complaint calls with duration > 0
        int complaintCallsCount = 0;
        for (final complaint in _complaintsController.complaints) {
          if ((complaint.callDuration ?? 0) > 0) {
            complaintCallsCount++;
          }
        }

        final callsTodayCount =
            (callsTodayLeads.length + complaintCallsCount).toString();

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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dashboard Section
                      _buildDashboardSection(
                        callsTodayCount,
                        totalFollowUpCount,
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions Section
                      _buildQuickActionsSection(),

                      const SizedBox(height: 24),

                      // Today's Follow Ups Section
                      _buildTodaysFollowUpsSection(todayFollowUpLeads),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardSection(String callsTodayCount, int followUpCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: TextConstant.dmSansMedium,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                count: callsTodayCount,
                title: 'Calls Today',
                icon: Icons.phone,
                bgColor: const Color(0xFFE3F2FD),
                iconColor: ColorConstant.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardCard(
                count: followUpCount.toString(),
                title: 'Follow Ups',
                icon: Icons.calendar_today,
                bgColor: Colors.white,
                iconColor: ColorConstant.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: TextConstant.dmSansMedium,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                icon: Icons.add,
                title: 'Add New Lead',
                onTap: () {
                  showAddLeadOutgoingCallBottomSheet(context);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionButton(
                icon: Icons.description,
                title: 'View Reports',
                onTap: () {
                  BottomNavState.navigateToReports();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                icon: Icons.warning_amber_rounded,
                title: 'Manage Complaints',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComplaintsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionButton(
                icon: Icons.people,
                title: 'Leads & Feedbacks',
                onTap: () {
                  BottomNavState.navigateToLeadScreen();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodaysFollowUpsSection(List followUpLeads) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Todays Follow Ups',
          subtitle: '${followUpLeads.length} Calls',
        ),
        const SizedBox(height: 12),
        if (_isLoadingFollowUps)
          const Center(child: CircularProgressIndicator())
        else if (followUpLeads.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No follow-ups for today',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: TextConstant.dmSansRegular,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: followUpLeads.length,
            itemBuilder: (context, index) {
              final lead = followUpLeads[index];
              return _buildFollowUpCard(lead);
            },
          ),
      ],
    );
  }

  Widget _buildFollowUpCard(dynamic lead) {
    return GestureDetector(
      onTap: () {
        // Navigate to follow-up detail screen
        if (lead.leadModel != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FollowupDetailScreen(lead: lead.leadModel!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F3FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.toMap()['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A2540),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '+91 ${lead.toMap()['phone'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontFamily: TextConstant.dmSansRegular,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pending • Booking',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: TextConstant.dmSansRegular,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}
