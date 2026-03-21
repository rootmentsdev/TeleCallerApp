import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/date_formatter.dart';

class BookingDetailScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String callType;
  final Map<String, dynamic>? reportData;

  const BookingDetailScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.callType,
    this.reportData,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late String _selectedService;
  late bool _billReceivedYes;
  late bool _billReceivedNo;
  late bool _amountMismatch;
  late TextEditingController _remarksController;
  bool _isSaving = false;

  final List<String> serviceOptions = ["Excellent", "Average", "Not satisfied"];

  @override
  void initState() {
    super.initState();
    _selectedService = "Average";
    _billReceivedYes = false;
    _billReceivedNo = false;
    _amountMismatch = false;
    _remarksController = TextEditingController();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  String _getDisplayValue(dynamic value, String defaultValue) {
    if (value == null || value.toString().isEmpty) {
      return defaultValue;
    }
    return value.toString();
  }

  /// Format ISO date string to readable format (e.g., "29 Jan, 2026")
  String _formatDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Not available';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormatter.formatDate(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return '00:00 Mins';

    int seconds = 0;
    if (duration is int) {
      seconds = duration;
    } else if (duration is String) {
      seconds = int.tryParse(duration) ?? 0;
    }

    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} Mins';
  }

  void _shareCallReport() {
    final data = widget.reportData ?? {};
    final shareText = '''
Booking Confirmation - ${widget.callType}

Customer: ${widget.name}
Phone: ${widget.phone}

Service: $_selectedService
Bill Received: ${_billReceivedYes ? 'Yes' : (_billReceivedNo ? 'No' : 'Not specified')}
Amount Mismatch: ${_amountMismatch ? 'Yes' : 'No'}

Remarks: ${_remarksController.text.isNotEmpty ? _remarksController.text : 'No remarks'}
''';
    Share.share(shareText);
  }

  Future<void> _saveCallUpdate() async {
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Add API call to save booking confirmation update
      // await apiService.updateBookingConfirmation(
      //   id: widget.reportData?['id'],
      //   service: _selectedService,
      //   billReceived: _billReceivedYes,
      //   amountMismatch: _amountMismatch,
      //   remarks: _remarksController.text,
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call update saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving call update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.reportData ?? {};
    final leadData = data['leadData'] ?? data;

    final location = _getDisplayValue(
      data['storeName'] ?? leadData['store'] ?? leadData['storeName'],
      'Not available',
    );
    final functionDate = _formatDateString(
      data['functionDate'] ??
          data['function_date'] ??
          leadData['functionDate'] ??
          leadData['function_date'],
    );
    final callDate = _formatDateString(
      data['callDate'] ??
          data['call_date'] ??
          leadData['callDate'] ??
          leadData['call_date'] ??
          data['createdAt'] ??
          data['created_at'],
    );
    final subCategory = _getDisplayValue(
      data['subCategory'] ??
          data['sub_category'] ??
          leadData['subCategory'] ??
          leadData['sub_category'],
      'N/A',
    );
    final closeAction = _getDisplayValue(
      data['closingAction'] ??
          data['closing_action'] ??
          leadData['closingAction'] ??
          leadData['closing_action'],
      'N/A',
    );
    final remarks = _getDisplayValue(
      data['remarks'] ?? leadData['remarks'],
      'No remarks',
    );
    final callDuration = _formatDuration(
      data['callDuration'] ?? data['call_duration'],
    );

    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Text(
                    'Reports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: TextConstant.dmSansMedium,
                    ),
                  ),
                  const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Card with Badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '+91 ${widget.phone}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontFamily: TextConstant.dmSansRegular,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorConstant.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Booking',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Call Details Section
                    Text(
                      'Call Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Call Date and Duration
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Call Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                callDate,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            callDuration,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location and Function Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                location,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Function Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                functionDate,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sub Category and Close Action
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sub Category',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subCategory,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Close Action',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                closeAction,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Remarks
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remarks / Notes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          remarks,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Follow Up Section
                    Text(
                      'Follow Up',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Follow Up Call Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Call Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              callDate,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                callDuration,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Follow Up Remarks
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remarks / Notes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          remarks,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Share Call Report Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _shareCallReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: ColorConstant.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Share Call Report',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: ColorConstant.primaryColor,
                            fontFamily: TextConstant.dmSansMedium,
                          ),
                        ),
                      ),
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
}
