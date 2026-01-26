import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/lead_display_model.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/navigation_helper.dart';
import 'package:telecaller_app/widgets.dart/app_header.dart';
import 'package:telecaller_app/view/profile_screen.dart';
import 'package:telecaller_app/widgets.dart/add_lead_outgoing_call_bottom_sheet.dart';
import 'package:telecaller_app/view/home_screen/bottomnavigation_bar.dart';
import 'package:telecaller_app/view/complaints_screen/complaints_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingFollowUps = false;
  final LeadRepository _repository = LeadRepository();

  @override
  void initState() {
    super.initState();

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

      leadController.init(headerController);
      leadController.refresh();

      Future.delayed(const Duration(milliseconds: 500), () {
        _fetchFollowUpLeads(headerController);
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
    super.dispose();
  }

  String? _getStoreParam(String? store) {
    return (store == null || store == 'All Stores') ? null : store;
  }

  Future<void> _fetchFollowUpLeads(
    HeaderController headerController,
  ) async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load follow-ups: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFollowUps = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HeaderController, LeadScreenController>(
      builder: (context, headerController, controller, child) {
        final callSummary = controller.getCallSummary();

        // Get today's follow-ups directly from repository
        final todayFollowUpLeads = _repository.todayFollowUps
            .map((lead) => LeadDisplayModel.fromLead(lead))
            .toList();

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
                      _buildDashboardSection(callSummary),

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


  Widget _buildDashboardSection(List<Map<String, dynamic>> callSummary) {
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
              child: _buildDashboardCard(
                count: callSummary[0]['count'],
                title: 'Calls Today',
                icon: Icons.phone,
                bgColor: const Color(0xFFE3F2FD),
                iconColor: ColorConstant.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDashboardCard(
                count: callSummary[3]['count'],
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

  Widget _buildDashboardCard({
    required String count,
    required String title,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A2540),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: TextConstant.dmSansRegular,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: iconColor, size: 28),
        ],
      ),
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
              child: _buildActionButton(
                icon: Icons.add,
                title: 'Add New Lead',
                onTap: () {
                  showAddLeadOutgoingCallBottomSheet(context);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.description,
                title: 'View Reports',
                onTap: () {
                  // Navigate to reports screen using bottom nav
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
              child: _buildActionButton(
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
              child: _buildActionButton(
                icon: Icons.people,
                title: 'Leads & Feedbacks',
                onTap: () {
                  // Navigate to lead screen using bottom nav
                  BottomNavState.navigateToLeadScreen();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: ColorConstant.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontFamily: TextConstant.dmSansMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysFollowUpsSection(List followUpLeads) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Todays Follow Ups',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: TextConstant.dmSansMedium,
              ),
            ),
            Text(
              '${followUpLeads.length} Calls',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE23434),
              ),
            ),
          ],
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
        // Navigate to detail screen
        if (lead.leadModel != null) {
          NavigationHelper.navigateToDetails(
            context,
            lead.leadModel!,
            lead.date,
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
