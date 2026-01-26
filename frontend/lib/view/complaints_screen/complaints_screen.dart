import 'package:flutter/material.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  String _selectedStore = 'All Stores';
  final List<Map<String, dynamic>> complaints = [
    {
      'name': 'Abhiram',
      'phone': '+91 98765 43210',
      'type': 'Enquiry',
      'date': '18 Jan 2026 12:05 pm',
      'store': 'Zorucci Edappally',
      'functionDate': '23 Jan 2026',
      'subCategory': 'Product Damage',
      'remarks':
          'Product received with visible damage and scratches. Customer reports the outfit is not wearable for the event.',
      'isExpanded': true,
    },
    {
      'name': 'Abhiram',
      'phone': '+91 98765 43210',
      'type': 'Enquiry',
      'date': '18 Jan 2026 12:05 pm',
      'store': 'Zorucci Edappally',
      'subCategory': 'Product Damage',
      'remarks': 'Product received with visible damage and scratches. Custo...',
      'isExpanded': false,
    },
    {
      'name': 'Abhiram',
      'phone': '+91 98765 43210',
      'type': 'Enquiry',
      'date': '18 Jan 2026 12:05 pm',
      'store': 'Zorucci Edappally',
      'subCategory': 'Product Damage',
      'remarks': 'Product received with visible damage and scratches. Custo...',
      'isExpanded': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Custom Header
          Container(
            color: ColorConstant.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Complaints',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: TextConstant.dmSansMedium,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Complaints Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Complaints',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: TextConstant.dmSansMedium,
                        ),
                      ),
                      Text(
                        '${complaints.length} Complaints',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE23434),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Store Filter
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedStore,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  fontFamily: TextConstant.dmSansMedium,
                                ),
                              ),
                              Icon(Icons.expand_more, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Complaints List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = complaints[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildComplaintCard(complaint, index),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint, int index) {
    final isExpanded = complaint['isExpanded'] ?? false;

    if (isExpanded) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint['phone'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: TextConstant.dmSansRegular,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    complaint['type'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              complaint['date'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontFamily: TextConstant.dmSansRegular,
              ),
            ),
            const SizedBox(height: 16),

            // Store & Location
            _buildDetailRow('Store & Location', complaint['store']),
            const SizedBox(height: 12),

            // Function Date
            _buildDetailRow(
              'Function Date',
              complaint['functionDate'] ?? 'N/A',
            ),
            const SizedBox(height: 12),

            // Sub Category
            _buildDetailRow('Sub Category', complaint['subCategory']),
            const SizedBox(height: 12),

            // Call Remarks
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Call Remarks / Notes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  complaint['remarks'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontFamily: TextConstant.dmSansRegular,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint['phone'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: TextConstant.dmSansRegular,
                      ),
                    ),
                  ],
                ),
                Text(
                  complaint['date'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontFamily: TextConstant.dmSansRegular,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              complaint['subCategory'],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE23434),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              complaint['remarks'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: TextConstant.dmSansRegular,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  complaint['store'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: TextConstant.dmSansRegular,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to complaint details
                  },
                  child: Row(
                    children: [
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Color(0xFF2196F3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
