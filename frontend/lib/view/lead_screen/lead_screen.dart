import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/utils/navigation_helper.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/widgets.dart/app_header.dart';
import 'package:telecaller_app/view/profile_screen.dart';
import 'package:intl/intl.dart';

class LeadScreen extends StatefulWidget {
  const LeadScreen({super.key});

  @override
  State<LeadScreen> createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LeadRepository _repository = LeadRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _repository.addListener(_onDataChanged);

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
    });
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repository.removeListener(_onDataChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HeaderController>(
      builder: (context, headerController, _) {
        final store = headerController.selectedStore;
        final allLeads = _repository.allLeads;

        List<LeadModel> applyStoreFilter(List<LeadModel> leads) {
          if (store.normalizedName == 'All Stores') return leads;
          return leads
              .where((l) => _repository.matchesStore(l, store.normalizedName))
              .toList();
        }

        final feedbackLeads = applyStoreFilter(
          allLeads
              .where(
                (l) =>
                    l.category == LeadConstants.categoryRentOut ||
                    l.category == 'Return',
              )
              .toList(),
        );

        final bookingLeads = applyStoreFilter(
          allLeads
              .where(
                (l) => l.category == LeadConstants.categoryBookingConfirmation,
              )
              .toList(),
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F7),
          body: Column(
            children: [
              AppHeader(
                onNotificationTap: () {},
                onProfileTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildTabBar(feedbackLeads.length, bookingLeads.length),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLeadList(feedbackLeads),
                            _buildLeadList(bookingLeads),
                          ],
                        ),
                      ),
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

  Widget _buildTabBar(int feedbackCount, int bookingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return Row(
            children: [
              _tabChip(
                'Feedback Calls ($feedbackCount)',
                0,
                _tabController.index == 0,
              ),
              const SizedBox(width: 12),
              _tabChip(
                'Booking Confirmation ($bookingCount)',
                1,
                _tabController.index == 1,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tabChip(String label, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstant.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: TextConstant.dmSansMedium,
            color: isSelected ? Colors.white : const Color(0xFFE07B00),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadList(List<LeadModel> leads) {
    if (leads.isEmpty) {
      return Center(
        child: Text(
          'No leads found',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
            fontFamily: TextConstant.dmSansRegular,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: leads.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildLeadTile(leads[index]),
    );
  }

  Widget _buildLeadTile(LeadModel lead) {
    final date = lead.getEffectiveDate();
    final formattedDate = DateFormat('d MMM, yyyy').format(date);

    return InkWell(
      onTap:
          () =>
              NavigationHelper.navigateToDetails(context, lead, formattedDate),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: Color(0xFF6B7A99),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0A2540),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '+91 ${lead.phone}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: TextConstant.dmSansRegular,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF6B7A99),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontFamily: TextConstant.dmSansRegular,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
