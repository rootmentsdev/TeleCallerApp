import 'package:flutter/material.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/text_constant.dart';

/// Popup sheet for incoming call with booking confirmation lead details
/// Shows booking information with editable fields
class IncomingCallBookingPopupSheet extends StatefulWidget {
  final LeadModel lead;
  final int? callDuration;
  final Function(
    String? service,
    bool? billReceived,
    bool? amountMismatch,
    String? remarks,
    bool? markAsComplaint,
    bool? markAsFollowup,
    DateTime? followupDate,
  )
  onSave;

  const IncomingCallBookingPopupSheet({
    super.key,
    required this.lead,
    this.callDuration,
    required this.onSave,
  });

  @override
  State<IncomingCallBookingPopupSheet> createState() =>
      _IncomingCallBookingPopupSheetState();
}

class _IncomingCallBookingPopupSheetState
    extends State<IncomingCallBookingPopupSheet> {
  late TextEditingController _serviceController;
  late TextEditingController _remarksController;
  bool _billReceived = false;
  bool _amountMismatch = false;
  bool _markAsComplaint = false;
  bool _markAsFollowup = false;
  DateTime? _followupDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _serviceController = TextEditingController(text: '');
    _remarksController = TextEditingController(text: widget.lead.reason ?? '');
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      await widget.onSave(
        _serviceController.text.trim(),
        _billReceived,
        _amountMismatch,
        _remarksController.text.trim(),
        _markAsComplaint,
        _markAsFollowup,
        _followupDate,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectFollowupDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _followupDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _followupDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lead.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+91 ${widget.lead.phone}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
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
                color: Colors.grey[800],
                fontFamily: TextConstant.dmSansMedium,
              ),
            ),

            const SizedBox(height: 12),

            // Location and Attended by
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
                        widget.lead.brand != null &&
                                widget.lead.location != null
                            ? '${widget.lead.brand} - ${widget.lead.location}'
                            : widget.lead.location ??
                                widget.lead.brand ??
                                'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
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
                        'Attended by',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: TextConstant.dmSansRegular,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Booking Date and Pick Up Date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: TextConstant.dmSansRegular,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(widget.lead.bookingDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
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
                        'Pick Up Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: TextConstant.dmSansRegular,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(widget.lead.functionDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Editable Fields Section
            Text(
              'Booking Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontFamily: TextConstant.dmSansMedium,
              ),
            ),

            const SizedBox(height: 12),

            // Service
            TextField(
              controller: _serviceController,
              decoration: InputDecoration(
                labelText: 'Service',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Bill Received
            CheckboxListTile(
              value: _billReceived,
              onChanged: (value) {
                setState(() => _billReceived = value ?? false);
              },
              title: const Text('Bill Received'),
              contentPadding: EdgeInsets.zero,
            ),

            // Amount Mismatch
            CheckboxListTile(
              value: _amountMismatch,
              onChanged: (value) {
                setState(() => _amountMismatch = value ?? false);
              },
              title: const Text('Amount Mismatch'),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 12),

            // Remarks
            TextField(
              controller: _remarksController,
              decoration: InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Mark as Complaint
            CheckboxListTile(
              value: _markAsComplaint,
              onChanged: (value) {
                setState(() => _markAsComplaint = value ?? false);
              },
              title: const Text('Mark as Complaint'),
              contentPadding: EdgeInsets.zero,
            ),

            // Mark as Followup
            CheckboxListTile(
              value: _markAsFollowup,
              onChanged: (value) {
                setState(() => _markAsFollowup = value ?? false);
              },
              title: const Text('Mark as Followup'),
              contentPadding: EdgeInsets.zero,
            ),

            // Followup Date (show if marked as followup)
            if (_markAsFollowup)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton(
                  onPressed: _selectFollowupDate,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _followupDate == null
                        ? 'Select Followup Date'
                        : 'Followup: ${_formatDate(_followupDate)}',
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: Color(0xFFE0E0E0),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003D7A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child:
                        _isSaving
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Save Booking Update',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
