import 'package:flutter/material.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/services/phone_call_service.dart';

class MarkedCallsDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> callData;

  const MarkedCallsDetailsScreen({super.key, required this.callData});

  @override
  State<MarkedCallsDetailsScreen> createState() =>
      _MarkedCallsDetailsScreenState();
}

class _MarkedCallsDetailsScreenState extends State<MarkedCallsDetailsScreen> {
  late Map<String, dynamic> _callData;

  @override
  void initState() {
    super.initState();
    _callData = widget.callData;
  }

  Future<void> _makeCall() async {
    try {
      final phoneNumber = _callData['phone'] ?? '';
      if (phoneNumber.isNotEmpty) {
        await PhoneCallService.makeCall(phoneNumber);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final horizontalPadding = isMobile ? 16.0 : 24.0;
    final verticalPadding = isMobile ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      body: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 10),
                        child: const Text(
                          "Marked Calls | Rent Out Feedback",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: TextConstant.dmSansMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _callData['storeName'] ?? "Store",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _callData['isMarked'] = !(_callData['isMarked'] ?? false);
                    });
                  },
                  child: Icon(
                    (_callData['isMarked'] ?? false)
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Customer Information
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: isMobile ? 48 : 56,
                          height: isMobile ? 48 : 56,
                          decoration: BoxDecoration(
                            color: _getAvatarColor(_callData['name'] ?? ''),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              (_callData['name'] ?? 'N')[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 20 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _callData['name'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: TextConstant.dmSansMedium,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _callData['phone'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 14,
                                  color: Colors.grey[700],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Call Details Section
                    _buildSectionTitle("CALL DETAILS"),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      "Call Date",
                      _callData['date'] ?? _callData['callDate'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      "Duration",
                      _formatDuration(_callData['callDuration'] ?? 0),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      "Call Status",
                      _callData['callStatus'] ?? 'N/A',
                    ),

                    const SizedBox(height: 24),

                    // Booking Details Section
                    _buildSectionTitle("BOOKING DETAILS"),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      "Booking Number",
                      _callData['bookingNumber'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      "Booking Date",
                      _callData['bookingDate'] ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      "Attended By",
                      _callData['attendedBy'] ?? 'N/A',
                    ),

                    const SizedBox(height: 24),

                    // Security Amount Section
                    _buildSectionTitle("SECURITY AMOUNT"),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      "Amount",
                      _callData['securityAmount'] ?? 'N/A',
                    ),

                    const SizedBox(height: 24),

                    // Rating Section
                    _buildSectionTitle("RATING"),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(5, (index) {
                        final rating = _callData['rating'] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.star,
                            size: isMobile ? 28 : 32,
                            color:
                                index < rating
                                    ? Colors.amber
                                    : Colors.grey[300],
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // Remarks Section
                    _buildSectionTitle("REMARKS"),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: Text(
                        _callData['remarks'] ??
                            _callData['reason'] ??
                            'No remarks',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.grey[700],
                          fontFamily: TextConstant.dmSansRegular,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _makeCall,
                            icon: const Icon(Icons.call),
                            label: const Text("Call Now"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstant.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _shareDetails,
                            icon: const Icon(Icons.share),
                            label: const Text("Share Details"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[800],
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 12 : 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
        fontFamily: TextConstant.dmSansMedium,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: TextConstant.dmSansRegular,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
              fontFamily: TextConstant.dmSansMedium,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return "0s";
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes == 0) return "${secs}s";
    if (secs == 0) return "${minutes}m";
    return "${minutes}m ${secs}s";
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFE8E3FF),
      const Color(0xFFFFE8E8),
      const Color(0xFFFFF7CC),
      const Color(0xFFD4F5DA),
      const Color(0xFFD5E8FF),
    ];
    return colors[name.hashCode % colors.length];
  }
}
