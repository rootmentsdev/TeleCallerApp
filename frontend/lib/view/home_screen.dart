import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/home_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/widgets.dart/call_card.dart';
import 'package:telecaller_app/widgets.dart/app_header.dart';
import 'package:telecaller_app/widgets.dart/call_summary_card.dart';
import 'package:telecaller_app/view/call_card_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize controller with header controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final headerController = Provider.of<HeaderController>(
        context,
        listen: false,
      );
      final homeController = Provider.of<HomeController>(
        context,
        listen: false,
      );
      homeController.init(headerController);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HeaderController, HomeController>(
      builder: (context, headerController, homeController, child) {
        final callSummary = homeController.getCallSummary();
        final callList = homeController.getCallList();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              children: [
                AppHeader(
                  userName: "Shafna",
                  showDate: true,
                  fullWidthStore: true,
                  onNotificationTap: () {
                    // Handle notification tap
                  },
                ),

                // Call Summary Cards - Horizontal Scroll
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: callSummary.length,
                      itemBuilder: (context, index) {
                        final item = callSummary[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SizedBox(
                            width: 80,
                            child: CallSummaryCard(
                              title: item["title"],
                              count: item["count"],
                              bgColor: item["bgColor"],
                              iconColor: item["iconColor"],
                              icon: item["icon"],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                    // top: 10,
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  child: Container(
                    height: 352,
                    width: double.infinity,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Calls Overview",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontFamily: TextConstant.dmSansMedium,
                                  fontSize: 18,
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: headerController.selectedDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedDate != null) {
                                    headerController.setSelectedDate(
                                      pickedDate,
                                    );
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: ColorConstant.primaryColor
                                        .withOpacity(0.1),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        color: ColorConstant.primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(headerController.selectedDate),
                                        style: TextStyle(
                                          color: ColorConstant.primaryColor,
                                          fontFamily: TextConstant.dmSansMedium,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: ColorConstant.primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey[300]),
                        Expanded(
                          child: ListView.builder(
                            itemCount: callList.length,
                            itemBuilder: (context, index) {
                              final item = callList[index];
                              return CallCard(
                                icon: item["icon"],
                                title: item["title"],
                                subtitle: item["subtitle"],
                                count: item["count"],
                                bgColor: item["bgColor"],
                                iconColor: item["iconColor"],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => CallCardDetailsScreen(
                                            title: item["title"],
                                            subtitle: item["subtitle"],
                                            count: item["count"],
                                            bgColor: item["bgColor"],
                                            iconColor: item["iconColor"],
                                            icon: item["icon"],
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
