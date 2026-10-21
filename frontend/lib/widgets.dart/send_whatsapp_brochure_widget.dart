import 'package:flutter/material.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/utils/text_constant.dart';

class SendWhatsappBrochureWidget extends StatefulWidget {
  final String customerPhone;
  final String customerName;
  final String? initialBrand;

  const SendWhatsappBrochureWidget({
    super.key,
    required this.customerPhone,
    required this.customerName,
    this.initialBrand,
  });

  @override
  State<SendWhatsappBrochureWidget> createState() =>
      _SendWhatsappBrochureWidgetState();
}

class _SendWhatsappBrochureWidgetState
    extends State<SendWhatsappBrochureWidget> {
  bool _sendWhatsappMessage = false;
  String _selectedBrand = 'suitor_guy';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _selectedBrand = _detectBrand(widget.initialBrand);
  }

  @override
  void didUpdateWidget(covariant SendWhatsappBrochureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialBrand != widget.initialBrand) {
      _selectedBrand = _detectBrand(widget.initialBrand);
    }
  }

  String _detectBrand(String? brand) {
    if (brand != null && brand.toLowerCase().contains('zorucci')) {
      return 'zorucci';
    }
    return 'suitor_guy';
  }

  Future<void> _sendWhatsappMessageAction() async {
    String cleanPhone = widget.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
      cleanPhone = cleanPhone.substring(2);
    }

    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer phone number is not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cleanName = widget.customerName.trim().isEmpty ||
            widget.customerName == 'Unknown' ||
            widget.customerName == 'N/A'
        ? 'Customer'
        : widget.customerName.trim();

    setState(() {
      _isSending = true;
    });

    try {
      final apiService = ApiService();
      await apiService.sendBrochureTemplate(
        customerPhone: cleanPhone,
        customerName: cleanName,
        brand: _selectedBrand,
      );

      if (mounted) {
        final brandDisplayName =
            _selectedBrand == 'zorucci' ? 'Zorucci' : 'Suitor Guy';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'WhatsApp brochure sent to $cleanPhone ($brandDisplayName)',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _sendWhatsappMessage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send WhatsApp message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _sendWhatsappMessage
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _sendWhatsappMessage
              ? const Color(0xFF86EFAC)
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _sendWhatsappMessage,
                  activeColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _sendWhatsappMessage = val ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _sendWhatsappMessage = !_sendWhatsappMessage;
                    });
                  },
                  child: const Row(
                    children: [
                      Icon(
                        Icons.chat,
                        size: 18,
                        color: Color(0xFF25D366),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Send WhatsApp Message',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontFamily: TextConstant.dmSansMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_sendWhatsappMessage) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBrand,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey,
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'suitor_guy',
                            child: Text('Suitor Guy'),
                          ),
                          DropdownMenuItem(
                            value: 'zorucci',
                            child: Text('Zorucci'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedBrand = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendWhatsappMessageAction,
                  icon: _isSending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    _isSending ? 'Sending...' : 'Send',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: TextConstant.dmSansMedium,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
