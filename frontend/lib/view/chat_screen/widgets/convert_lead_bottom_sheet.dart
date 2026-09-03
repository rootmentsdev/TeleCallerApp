import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/chat_controller.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/model/store_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';

class ConvertLeadBottomSheet extends StatefulWidget {
  final String conversationId;
  final String participantName;
  final String participantPhone;

  const ConvertLeadBottomSheet({
    super.key,
    required this.conversationId,
    required this.participantName,
    required this.participantPhone,
  });

  @override
  State<ConvertLeadBottomSheet> createState() => _ConvertLeadBottomSheetState();
}

class _ConvertLeadBottomSheetState extends State<ConvertLeadBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  String _selectedLeadType = 'enquiry';
  Store? _selectedStore; // Dynamic store
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.participantName;
    _phoneController.text = widget.participantPhone;
    _remarksController.text = 'Converted from chat';
    
    // Set default store from header controller if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final headerController = Provider.of<HeaderController>(context, listen: false);
      if (headerController.availableStores.isNotEmpty) {
        setState(() {
          _selectedStore = headerController.availableStores.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _convertLead() async {
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a store')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final controller = Provider.of<ChatController>(context, listen: false);
    final response = await controller.convertToLead(widget.conversationId, {
      "customerName": _nameController.text,
      "phone": _phoneController.text,
      "leadtype": _selectedLeadType,
      "store": _selectedStore!.normalizedName, // Send the normalized store name
      "remarks": _remarksController.text,
      // Default for UI
      "functionDate": "2026-09-15",
      "markasFollowup": false,
      "markasComplaint": false
    });

    setState(() {
      _isLoading = false;
    });

    if (response != null && response['success'] == true) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead converted successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?['message'] ?? 'Failed to convert lead')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Convert Chat to CRM Lead',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            const Text('Select Lead Type *', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLeadType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'enquiry', child: Text('Enquiry')),
                    DropdownMenuItem(value: 'booked', child: Text('Booked')),
                    DropdownMenuItem(value: 'loss_of_sale', child: Text('Loss of Sale')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLeadType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('Phone Number *', _phoneController, Icons.phone),
            const SizedBox(height: 16),
            _buildTextField('Customer Name', _nameController, Icons.person),
            const SizedBox(height: 16),
            const Text('Brand / Store', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
            const SizedBox(height: 8),
            Consumer<HeaderController>(
              builder: (context, headerController, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Store>(
                      value: _selectedStore,
                      isExpanded: true,
                      hint: const Text('Select Store'),
                      items: headerController.availableStores.map((Store store) {
                        return DropdownMenuItem<Store>(
                          value: store,
                          child: Text(store.normalizedName),
                        );
                      }).toList(),
                      onChanged: (Store? val) {
                        if (val != null) setState(() => _selectedStore = val);
                      },
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 16),
            _buildTextField('Call Remarks / Notes', _remarksController, null, maxLines: 3),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _convertLead,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm & Create Lead'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData? prefixIcon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: Colors.grey) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}
