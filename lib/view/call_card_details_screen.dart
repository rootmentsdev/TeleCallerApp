import 'package:flutter/material.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';

class CallCardDetailsScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String count;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;

  const CallCardDetailsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Sample data for the list
    final List<Map<String, dynamic>> callDetails = [
      {
        "name": "John Doe",
        "phone": "+91 98765 43210",
        "date": "12 Nov, 2025",
        "time": "10:30 AM",
      },
      {
        "name": "Jane Smith",
        "phone": "+91 98765 43211",
        "date": "12 Nov, 2025",
        "time": "11:15 AM",
      },
      {
        "name": "Robert Johnson",
        "phone": "+91 98765 43212",
        "date": "12 Nov, 2025",
        "time": "02:45 PM",
      },
      {
        "name": "Emily Davis",
        "phone": "+91 98765 43213",
        "date": "13 Nov, 2025",
        "time": "09:20 AM",
      },
      {
        "name": "Michael Brown",
        "phone": "+91 98765 43214",
        "date": "13 Nov, 2025",
        "time": "03:30 PM",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ColorConstant.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: TextConstant.dmSansMedium,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColorConstant.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: iconColor, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontFamily: TextConstant.dmSansRegular,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: TextConstant.dmSansMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Call Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: TextConstant.dmSansMedium,
                  ),
                ),
                Text(
                  "Total: ${callDetails.length}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: TextConstant.dmSansRegular,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Call Details List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: callDetails.length,
              itemBuilder: (context, index) {
                final detail = callDetails[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: bgColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    title: Text(
                      detail["name"],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail["phone"],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontFamily: TextConstant.dmSansRegular,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${detail["date"]} • ${detail["time"]}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontFamily: TextConstant.dmSansRegular,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.phone,
                        color: ColorConstant.primaryColor,
                      ),
                      onPressed: () {
                        // Handle call action
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


