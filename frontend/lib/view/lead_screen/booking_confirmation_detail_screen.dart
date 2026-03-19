import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/date_formatter.dart';

class BookingConfirmationDetailScreen extends StatefulWidget {
  final LeadModel lead;

  const BookingConfirmationDetailScreen({super.key, required this.lead});

  @override
  State<BookingConfirmationDetailScreen> createState() =>
      _BookingConfirmationDetailScreenState();
}

class _BookingConfirmationDetailScreenState
    extends State<BookingConfirmationDetailScreen> {
  Map<String, dynamic> _detail = {};
  bool _isLoading = true;
  String? _error;
  bool _hasCalled = false;
  int _callDuration = 0;
  bool _isSaving = false;

  // Form fields matching the API body
  String? _selectedService;
  bool _billReceived = false;
  bool _amountMismatch = false;
  bool _markAsComplaint = false;
  bool _markAsFollowup = false;
  DateTime? _followupDate;
  final TextEditingController _remarksController = TextEditingController();

  final List<String> _serviceOptions = [
    'Excellent',
    'Average',
    'Not satisfied',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tracker = Provider.of<CallTrackingController>(
        context,
        listen: false,
      );
      tracker.initialize();
      tracker.addListener(_onCallUpdate);
    });
  }

  void _onCallUpdate() {
    final tracker = Provider.of<CallTrackingController>(context, listen: false);
    if ((tracker.lastDuration ?? 0) > 0 && mounted) {
      setState(() => _callDuration = tracker.lastDuration!);
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService().getBookingConfirmationById(
        widget.lead.id,
      );
      // Unwrap data key if present
      final data = response['data'] ?? response;
      if (mounted) {
        setState(() {
          _detail = data is Map<String, dynamic> ? data : {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makeCall() async {
    try {
      await PhoneCallService.makeCall(widget.lead.phone);
      if (mounted) setState(() => _hasCalled = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ApiService().updateBookingConfirmation(
        id: widget.lead.id,
        service: _selectedService,
        callDuration: _callDuration > 0 ? _callDuration.toString() : null,
        billReceived: _billReceived ? 'yes' : 'no',
        amountMismatch: _amountMismatch,
        remarks:
            _remarksController.text.isNotEmpty ? _remarksController.text : null,
        markasComplaint: _markAsComplaint ? true : null,
        markasFollowup: _markAsFollowup ? true : null,
        followupDate: _markAsFollowup ? _followupDate : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmation updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickFollowupDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _followupDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _followupDate = picked);
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'N/A';
    try {
      return DateFormatter.formatDate(DateTime.parse(value.toString()));
    } catch (_) {
      return value.toString();
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'N/A';
    try {
      final n = double.parse(value.toString());
      return '₹${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    } catch (_) {
      return value.toString();
    }
  }

  String _getStore() {
    final b = widget.lead.brand;
    final l = widget.lead.location;
    if (b != null && l != null) return '$b - $l';
    return b ?? l ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Booking Confirmation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? _buildError()
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailsCard(),
                            const SizedBox(height: 24),
                            if (!_hasCalled)
                              _buildCallButton()
                            else ...[
                              _buildFormSection(),
                              const SizedBox(height: 24),
                              _buildSaveButton(),
                            ],
                          ],
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text('Failed to load booking confirmation'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchDetail, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final attendedBy =
        _detail['attendedBy'] ??
        _detail['attended_by'] ??
        _detail['assignedTo']?['name'] ??
        'N/A';
    final bookingDate =
        _detail['bookingDate'] ??
        _detail['booking_date'] ??
        _detail['enquiryDate'] ??
        _detail['enquiry_date'];
    final pickupDate =
        _detail['pickupDate'] ??
        _detail['pickup_date'] ??
        _detail['functionDate'] ??
        _detail['function_date'];
    final advance =
        _detail['advanceAmount'] ??
        _detail['advance_amount'] ??
        _detail['advance'];
    final total =
        _detail['totalAmount'] ??
        _detail['total_amount'] ??
        _detail['productAmount'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Call Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: TextConstant.dmSansMedium,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.lead.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.lead.phone,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          _row2('Location', _getStore(), 'Attended by', attendedBy),
          const SizedBox(height: 16),
          _row2(
            'Booking Date',
            _formatDate(bookingDate),
            'Pick Up Date',
            _formatDate(pickupDate),
          ),
          const SizedBox(height: 16),
          _row2(
            'Advance Amount',
            _formatCurrency(advance),
            'Total Amount',
            _formatCurrency(total),
          ),
        ],
      ),
    );
  }

  Widget _row2(String l1, String v1, String l2, String v2) {
    return Row(
      children: [
        Expanded(child: _field(l1, v1)),
        Expanded(child: _field(l2, v2)),
      ],
    );
  }

  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: TextConstant.dmSansRegular,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: TextConstant.dmSansMedium,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildCallButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _makeCall,
        icon: const Icon(Icons.phone),
        label: const Text(
          'Call Now',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: TextConstant.dmSansMedium,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstant.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Call duration display
        if (_callDuration > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Call duration: ${_callDuration ~/ 60}:${(_callDuration % 60).toString().padLeft(2, '0')} min',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Service
        _label('Service'),
        const SizedBox(height: 8),
        _dropdown(
          value: _selectedService,
          hint: 'Select service rating',
          items: _serviceOptions,
          onChanged: (v) => setState(() => _selectedService = v),
        ),
        const SizedBox(height: 16),

        // Bill Received
        _toggleRow(
          'Bill Received',
          _billReceived,
          (v) => setState(() => _billReceived = v),
        ),
        const SizedBox(height: 12),

        // Amount Mismatch
        _toggleRow(
          'Amount Mismatch',
          _amountMismatch,
          (v) => setState(() => _amountMismatch = v),
        ),
        const SizedBox(height: 16),

        // Remarks
        _label('Remarks'),
        const SizedBox(height: 8),
        TextField(
          controller: _remarksController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add remarks...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 16),

        // Mark as Complaint
        _toggleRow(
          'Mark as Complaint',
          _markAsComplaint,
          (v) => setState(() => _markAsComplaint = v),
        ),
        const SizedBox(height: 12),

        // Mark as Follow-up
        _toggleRow(
          'Mark as Follow-up',
          _markAsFollowup,
          (v) => setState(() => _markAsFollowup = v),
        ),

        // Follow-up date picker
        if (_markAsFollowup) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickFollowupDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _followupDate != null
                        ? DateFormatter.formatDate(_followupDate!)
                        : 'Select follow-up date',
                    style: TextStyle(
                      color:
                          _followupDate != null
                              ? Colors.black87
                              : Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
        fontFamily: TextConstant.dmSansMedium,
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[500])),
          isExpanded: true,
          items:
              items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: ColorConstant.primaryColor,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstant.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isSaving
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: TextConstant.dmSansMedium,
                  ),
                ),
      ),
    );
  }
}
