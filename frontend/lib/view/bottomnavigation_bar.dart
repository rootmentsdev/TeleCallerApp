import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/view/followup_screen.dart';
import 'package:telecaller_app/view/home_screen.dart';
import 'package:telecaller_app/view/lead_screen.dart';
import 'package:telecaller_app/view/reports_screens/report_screen.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';
import 'package:telecaller_app/widgets.dart/add_lead_bottom_sheet.dart';
import 'package:telecaller_app/services/call_tracking_service.dart';
import 'package:telecaller_app/widgets.dart/add_lead_bottom_sheet.dart';
import 'package:telecaller_app/services/call_tracking_service.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key, this.initialIndex});

  final int? initialIndex;

  @override
  State<BottomNav> createState() => BottomNavState();
}

class BottomNavState extends State<BottomNav>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // Static reference to access from anywhere
  static BottomNavState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
    if (widget.initialIndex != null) {
      _currentIndex = widget.initialIndex!;
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Initialize call tracking
    _initializeCallTracking();
  }

  /// Initialize call tracking and set up callbacks
  void _initializeCallTracking() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callTrackingController = Provider.of<CallTrackingController>(
        context,
        listen: false,
      );

      // Initialize call tracking
      callTrackingController.initialize().then((success) {
        if (success) {
          print('BottomNav: Call tracking initialized successfully');

          // Set up callback for when calls end
          callTrackingController.setOnCallEndedCallback((
            phoneNumber,
            duration,
          ) {
            _handleCallEnded(phoneNumber, duration);
          });
        } else {
          print('BottomNav: Failed to initialize call tracking');
        }
      });
    });
  }

  /// Handle call ended event - show Add Lead bottom sheet for incoming calls
  void _handleCallEnded(String phoneNumber, int duration) {
    print(
      'BottomNav: Call ended - Phone: $phoneNumber, Duration: ${duration}s',
    );

    if (mounted) {
      // Get call data from controller
      final callTrackingController = Provider.of<CallTrackingController>(
        context,
        listen: false,
      );
      final callData = callTrackingController.lastEndedCall;

      // Show Add Lead bottom sheet for incoming calls that were not answered (duration = 0)
      // or for answered incoming calls (duration > 0)
      if (callData != null &&
          callData.callType == CallType.incoming &&
          phoneNumber != "Unknown" &&
          phoneNumber.isNotEmpty) {
        // Small delay to ensure UI is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            print(
              'BottomNav: Showing Add Lead bottom sheet for incoming call - Phone: $phoneNumber, Duration: ${duration}s',
            );

            showAddLeadBottomSheet(
              context,
              phoneNumber: phoneNumber,
              callDuration: duration,
              callData: callData,
            );
          }
        });
      } else {
        print(
          'BottomNav: Not showing Add Lead bottom sheet - CallType: ${callData?.callType}, Phone: $phoneNumber, Duration: ${duration}s',
        );
      }
    }
  }

  @override
  void dispose() {
    if (_instance == this) {
      _instance = null;
    }
    _controller.dispose();
    super.dispose();
  }

  // Method to change index from outside
  void changeIndex(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Static method to change index
  static void navigateToReports() {
    _instance?.changeIndex(3);
  }

  late final AnimationController _controller;

  final _pages = [
    const HomeScreen(),
    const LeadScreen(),
    const SizedBox(),
    const ReportScreen(),
    const FollowupScreen(),
  ];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _openAddLeadSheet() {
    _controller.forward().then((value) => _controller.reverse());

    showAddLeadBottomSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(side: BorderSide()),
        backgroundColor: ColorConstant.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _openAddLeadSheet(),
      ),

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _navItem(Icons.home_filled, "Home", 0)),
              Expanded(child: _navItem(Icons.people_alt, "Leads", 1)),
              // Spacer for FAB
              const SizedBox(width: 40),
              Expanded(
                child: _navItem(Icons.insert_drive_file_rounded, "Reports", 3),
              ),
              Expanded(child: _navItem(Icons.event_note, "Follow Ups", 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String text, int index) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onNavTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color:
                  isSelected ? ColorConstant.primaryColor : ColorConstant.grey,
            ),
            const SizedBox(height: 3),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: TextConstant.fontDMSans,
                color:
                    isSelected
                        ? ColorConstant.primaryColor
                        : ColorConstant.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
