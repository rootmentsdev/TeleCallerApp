import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/chat_controller.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/utils/text_constant.dart';

class SendBrochureBottomSheet extends StatefulWidget {
  final String conversationId;
  final String participantName;
  final String participantPhone;
  final String? initialBrand;
  final VoidCallback? onSuccess;

  const SendBrochureBottomSheet({
    super.key,
    required this.conversationId,
    required this.participantName,
    required this.participantPhone,
    this.initialBrand,
    this.onSuccess,
  });

  @override
  State<SendBrochureBottomSheet> createState() =>
      _SendBrochureBottomSheetState();
}

class _SendBrochureBottomSheetState extends State<SendBrochureBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedBrand = 'suitor_guy';
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    // 1. Clean and determine initial brand
    final rawBrand = widget.initialBrand?.toLowerCase() ?? '';
    if (rawBrand.contains('zorucci')) {
      _selectedBrand = 'zorucci';
    } else {
      _selectedBrand = 'suitor_guy';
    }

    // 2. Clean phone number
    String rawPhone = widget.participantPhone.isNotEmpty
        ? widget.participantPhone
        : widget.participantName;
    String digitsOnly = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      digitsOnly = digitsOnly.substring(2);
    } else if (digitsOnly.length > 10 && digitsOnly.startsWith('91')) {
      digitsOnly = digitsOnly.substring(digitsOnly.length - 10);
    }
    _phoneController.text = digitsOnly;

    // 3. Clean customer name
    String cleanedName =
        widget.participantName.replaceAll(RegExp(r'\(WhatsApp\)', caseSensitive: false), '').trim();
    // If name is just numbers or empty, default to "Customer"
    if (cleanedName.isEmpty || RegExp(r'^[0-9+\s\-]+$').hasMatch(cleanedName)) {
      cleanedName = 'Customer';
    }
    _nameController.text = cleanedName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendBrochure() async {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final name = _nameController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter customer name';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      await apiService.sendBrochureTemplate(
        customerPhone: phone,
        customerName: name,
        brand: _selectedBrand,
      );

      if (!mounted) return;

      final brandName =
          _selectedBrand == 'zorucci' ? 'Zorucci' : 'Suitor Guy';

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Automated WhatsApp brochure sent to $phone ($brandName)!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF25D366),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );

      // Trigger callback or refresh chat messages
      widget.onSuccess?.call();
      if (widget.conversationId.isNotEmpty) {
        Provider.of<ChatController>(context, listen: false)
            .fetchMessages(widget.conversationId, showLoading: false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to send brochure: $e';
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Color(0xFF25D366),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Send WhatsApp Brochure',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          fontFamily: TextConstant.dmSansBold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Automated brochure template message',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Brand Selection Label
            const Text(
              'Select Brand',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontFamily: TextConstant.dmSansMedium,
              ),
            ),
            const SizedBox(height: 8),

            // Brand Selector Cards
            Row(
              children: [
                Expanded(
                  child: _buildBrandCard(
                    title: 'Suitor Guy',
                    brandKey: 'suitor_guy',
                    icon: Icons.man,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBrandCard(
                    title: 'Zorucci',
                    brandKey: 'zorucci',
                    icon: Icons.woman,
                    color: const Color(0xFFBE185D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Customer Phone Field
            const Text(
              'Customer Phone Number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontFamily: TextConstant.dmSansMedium,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: const Text(
                    '+91',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: 'Enter 10-digit number',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Customer Name Field
            const Text(
              'Customer Name',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontFamily: TextConstant.dmSansMedium,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
                hintText: 'Customer Name',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                ),
              ),
            ),

            // Error display
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendBrochure,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF25D366).withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                label: Text(
                  _isSending ? 'Sending Template...' : 'Send WhatsApp Brochure',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: TextConstant.dmSansBold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandCard({
    required String title,
    required String brandKey,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedBrand == brandKey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedBrand = brandKey;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF0FDF4)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF25D366)
                : Colors.grey[300]!,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF16A34A) : color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF15803D)
                      : const Color(0xFF1F2937),
                  fontFamily: TextConstant.dmSansMedium,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF25D366),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
