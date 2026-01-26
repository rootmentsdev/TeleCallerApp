import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:telecaller_app/controller/complaints_controller.dart';
import 'package:telecaller_app/model/complaint_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final String _selectedStore = 'All Stores';
  late ComplaintsController _complaintsController;

  @override
  void initState() {
    super.initState();
    _complaintsController = ComplaintsController();

    // Fetch complaints on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchComplaints();
    });
  }

  Future<void> _fetchComplaints() async {
    await _complaintsController.fetchComplaints();
  }

  @override
  void dispose() {
    _complaintsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _complaintsController,
        builder: (context, _) {
          return Column(
            children: [
              // Custom Header
              Container(
                color: ColorConstant.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                child:
                    _complaintsController.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _complaintsController.error != null
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Error: ${_complaintsController.error}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchComplaints,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                        : _complaintsController.complaints.isEmpty
                        ? Center(
                          child: Text(
                            'No complaints found',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                        : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Recent Complaints Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    '${_complaintsController.totalComplaints} Complaints',
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
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _selectedStore,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                              fontFamily:
                                                  TextConstant.dmSansMedium,
                                            ),
                                          ),
                                          Icon(
                                            Icons.expand_more,
                                            color: Colors.grey[600],
                                          ),
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
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
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
                                itemCount:
                                    _complaintsController.complaints.length,
                                itemBuilder: (context, index) {
                                  final complaint =
                                      _complaintsController.complaints[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildComplaintCard(
                                      complaint,
                                      index,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _shareComplaint(ComplaintModel complaint) {
    final shareText = '''
Complaint Details:
Name: ${complaint.name}
Phone: ${complaint.phone}
Store: ${complaint.store}
Category: ${complaint.subCategory}
Date: ${complaint.date}
Remarks: ${complaint.remarks}
''';
    Share.share(shareText);
  }

  Widget _buildComplaintCard(ComplaintModel complaint, int index) {
    final isExpanded = complaint.isExpanded;

    if (isExpanded) {
      return GestureDetector(
        onDoubleTap: () {
          _complaintsController.toggleExpansion(index);
        },
        child: Container(
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
                        complaint.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        complaint.phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: TextConstant.dmSansRegular,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
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
                          complaint.type,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _shareComplaint(complaint),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.share,
                            color: Color(0xFF1976D2),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint.date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: TextConstant.dmSansRegular,
                ),
              ),
              const SizedBox(height: 16),

              // Store & Location
              _buildDetailRow('Store & Location', complaint.store),
              const SizedBox(height: 12),

              // Function Date
              _buildDetailRow(
                'Function Date',
                complaint.functionDate.isEmpty ? 'N/A' : complaint.functionDate,
              ),
              const SizedBox(height: 12),

              // Sub Category
              _buildDetailRow('Sub Category', complaint.subCategory),
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
                    complaint.remarks,
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
                      complaint.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: TextConstant.dmSansRegular,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      complaint.date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontFamily: TextConstant.dmSansRegular,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _shareComplaint(complaint),
                      child: Icon(
                        Icons.share,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              complaint.subCategory,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE23434),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              complaint.remarks,
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
                  complaint.store,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: TextConstant.dmSansRegular,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _complaintsController.toggleExpansion(index);
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
