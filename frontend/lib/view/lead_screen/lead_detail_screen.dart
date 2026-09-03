import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/date_formatter.dart';

class LeadDetailScreen extends StatefulWidget {
  final LeadModel lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  bool _isLoading = false;
  bool _hasCalled = false;
  int _callDuration = 0;
  bool _isSaving = false;

  // Form fields
  String? _selectedLeadType;
  String? _selectedStore;
  DateTime? _functionDate;
  final TextEditingController _remarksController = TextEditingController();
  bool _markAsFollowup = false;
  DateTime? _followupDate;
  bool _markAsComplaint = false;

  final List<String> _leadTypeOptions = ['enquiry', 'booked', 'lossOfSale'];
  
  // Hardcoded for now; realistically, you'd fetch this from the backend
  final List<String> _storeOptions = [
    'Zorucci Edappally',
    'SG-General',
    'Suitor Guy',
    'Dapper Squad'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select based on current lead
    _selectedLeadType = widget.lead.category;
    if (!_leadTypeOptions.contains(_selectedLeadType)) {
      _selectedLeadType = 'enquiry'; // Fallback
    }
    
    _selectedStore = widget.lead.location;
    if (_selectedStore != null && !_storeOptions.contains(_selectedStore)) {
       // Just add it if it's missing to avoid errors, or fallback
       if (_selectedStore!.isNotEmpty) {
         _storeOptions.add(_selectedStore!);
       } else {
         _selectedStore = null;
       }
    }

    if (widget.lead.functionDate != null) {
      _functionDate = widget.lead.functionDate;
    }
    
    _remarksController.text = widget.lead.reason ?? '';

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
    if (_selectedLeadType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Lead Type'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Determine which API to call based on original or new lead type?
      // Typically you'd call an update API for the *current* category.
      final apiService = ApiService();
      
      // We will create a generic update method in api_service for these.
      await apiService.updateGenericLead(
        id: widget.lead.id,
        category: widget.lead.category ?? 'enquiry', // Original category to hit the right endpoint
        newLeadType: _selectedLeadType,
        store: _selectedStore,
        functionDate: _functionDate,
        remarks: _remarksController.text,
        markAsFollowup: _markAsFollowup,
        followupDate: _followupDate,
        markAsComplaint: _markAsComplaint,
        callDuration: _callDuration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lead updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Pop and optionally refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate(bool isFollowup) async {
    final initialDate = isFollowup ? (_followupDate ?? DateTime.now()) : (_functionDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isFollowup ? DateTime.now() : DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (picked != null && mounted) {
      setState(() {
        if (isFollowup) {
          _followupDate = picked;
        } else {
          _functionDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      appBar: AppBar(
        backgroundColor: ColorConstant.primaryColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: const Text(
          'Lead Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: TextConstant.dmSansMedium,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCustomerCard(),
                    const SizedBox(height: 24),
                    if (!_hasCalled) _buildCallButton() else ...[
                      _buildFormSection(),
                      const SizedBox(height: 24),
                      _buildSaveButton(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: ColorConstant.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.lead.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.lead.phone,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.category, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                'Source: ${widget.lead.category?.toUpperCase() ?? 'N/A'}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
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
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstant.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          
        _label('Lead Type *'),
        const SizedBox(height: 8),
        _dropdown(
          value: _selectedLeadType,
          hint: 'Select lead type',
          items: _leadTypeOptions,
          onChanged: (v) => setState(() => _selectedLeadType = v),
        ),
        const SizedBox(height: 16),

        _label('Brand / Store'),
        const SizedBox(height: 8),
        _dropdown(
          value: _selectedStore,
          hint: 'Select store',
          items: _storeOptions,
          onChanged: (v) => setState(() => _selectedStore = v),
        ),
        const SizedBox(height: 16),
        
        _label('Function Date'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDate(false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 10),
                Text(
                  _functionDate != null ? DateFormatter.formatDate(_functionDate!) : 'Select function date',
                  style: TextStyle(
                    color: _functionDate != null ? Colors.black87 : Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _label('Remarks'),
        const SizedBox(height: 8),
        TextField(
          controller: _remarksController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter remarks...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
        const SizedBox(height: 16),

        _toggleRow('Mark as Follow-up', _markAsFollowup, (v) => setState(() => _markAsFollowup = v)),
        
        if (_markAsFollowup) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _pickDate(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 10),
                  Text(
                    _followupDate != null ? DateFormatter.formatDate(_followupDate!) : 'Select follow-up date',
                    style: TextStyle(
                      color: _followupDate != null ? Colors.black87 : Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        _toggleRow('Mark as Complaint', _markAsComplaint, (v) => setState(() => _markAsComplaint = v)),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Submit details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey[800],
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
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _label(label),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: ColorConstant.primaryColor,
        ),
      ],
    );
  }
}
