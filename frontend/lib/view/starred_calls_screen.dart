import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/starred_calls_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/view/details_screen.dart';
import 'package:telecaller_app/widgets.dart/app_header.dart';
import 'package:telecaller_app/view/profile_screen.dart';

class StarredCallsScreen extends StatefulWidget {
  const StarredCallsScreen({super.key});

  @override
  State<StarredCallsScreen> createState() => _StarredCallsScreenState();
}

class _StarredCallsScreenState extends State<StarredCallsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final headerController = Provider.of<HeaderController>(
        context,
        listen: false,
      );
      final starredController = Provider.of<StarredCallsController>(
        context,
        listen: false,
      );
      starredController.init(headerController);

      // Fetch starred calls from API
      try {
        await starredController.fetchStarredCalls();
      } catch (e) {
        print('StarredCallsScreen: Error fetching starred calls: $e');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final starredController = Provider.of<StarredCallsController>(
        context,
        listen: false,
      );
      try {
        await starredController.fetchStarredCalls();
      } catch (e) {
        print('StarredCallsScreen: Error refreshing starred calls: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HeaderController, StarredCallsController>(
      builder: (context, headerController, starredController, child) {
        final currentLeads = starredController.getCurrentLeads();

        // Category tabs
        final categories = [
          "All",
          "Loss of Sales",
          "Return",
          "Booking confirmation",
          "Feedback",
        ];

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                showDate: false,
                showFilters: true,
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
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: const Text(
                  "Starred Calls",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: TextConstant.dmSansMedium,
                  ),
                ),
              ),
              // Category tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children:
                      categories.map((category) {
                        final isSelected =
                            starredController.selectedCategory == category ||
                            (starredController.selectedCategory == null &&
                                category == "All");
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              starredController.setSelectedCategory(
                                category == "All" ? null : category,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? ColorConstant.primaryColor
                                        : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: TextConstant.fontDMSans,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Leads list
              Expanded(
                child:
                    starredController.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : currentLeads.isEmpty
                        ? Center(
                          child: Text(
                            "No starred calls found",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: TextConstant.fontDMSans,
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: currentLeads.length,
                          itemBuilder: (context, index) {
                            final lead = currentLeads[index];
                            final displayMap = starredController
                                .leadToDisplayMap(lead);

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => DetailsScreen(
                                          contact: displayMap,
                                          callTypeIndex: 0,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: displayMap["borderColor"],
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    // Icon
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: displayMap["iconBgColor"],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        displayMap["icon"],
                                        color: displayMap["iconColor"],
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Lead info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayMap["name"],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              fontFamily:
                                                  TextConstant.dmSansMedium,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            displayMap["phone"],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontFamily:
                                                  TextConstant.fontDMSans,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: displayMap["tagBgColor"],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        displayMap["tag"],
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: displayMap["tagColor"],
                                          fontFamily: TextConstant.fontDMSans,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}
