const fs = require('fs');
const path = require('path');

const directory = 'c:\\flutter_apps\\telecaller_app\\frontend\\lib\\widgets.dart';
const files = [
    'incoming_call_report_popup_sheet.dart',
    'incoming_call_followup_popup_sheet.dart',
    'incoming_call_justdial_popup_sheet.dart'
];

const helperMethod = `
  Widget _buildDropdownField({
    required String? value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final validValue = (value != null && items.contains(value)) ? value : null;
    final isDisabled = items.isEmpty;

    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                isDisabled ? const Color(0xFFCCCCCC) : const Color(0xFFE0E0E0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                isDisabled ? const Color(0xFFCCCCCC) : const Color(0xFFE0E0E0),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF003D7A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: isDisabled,
        fillColor: isDisabled ? const Color(0xFFF5F5F5) : Colors.white,
      ),
      items:
          items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis, maxLines: 1),
            );
          }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return items.map((item) {
          return Text(item, overflow: TextOverflow.ellipsis, maxLines: 1);
        }).toList();
      },
      onChanged: isDisabled ? null : onChanged,
    );
  }
`;

const dropdownUI = `            // Send WhatsApp Message
            Row(
              children: [
                Checkbox(
                  value: _sendWhatsappMessage,
                  onChanged: (value) {
                    setState(() {
                      _sendWhatsappMessage = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF003D7A),
                ),
                const Text(
                  "Send WhatsApp Message",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
            if (_sendWhatsappMessage) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      value: _selectedBrand,
                      label: 'Store',
                      items: StoreLocations.brandStores.keys.toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBrand = value;
                          _selectedLocation = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      value: _selectedLocation,
                      label: 'Location',
                      items:
                          _selectedBrand != null
                              ? (StoreLocations
                                      .brandStores[_selectedBrand!] ??
                                  [])
                              : [],
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],`;

for (const file of files) {
    const filePath = path.join(directory, file);
    if (!fs.existsSync(filePath)) continue;
    
    let content = fs.readFileSync(filePath, 'utf8');
    let modified = false;

    if (!content.includes("import 'package:telecaller_app/utils/store_location.dart';")) {
        content = content.replace(
            "import 'package:telecaller_app/services/api_service.dart';",
            "import 'package:telecaller_app/services/api_service.dart';\nimport 'package:telecaller_app/utils/store_location.dart';"
        );
        modified = true;
    }

    if (!content.includes("String? _selectedBrand;")) {
        content = content.replace(
            "bool _sendWhatsappMessage = false;",
            "bool _sendWhatsappMessage = false;\n  String? _selectedBrand;\n  String? _selectedLocation;"
        );
        modified = true;
    }

    if (!content.includes("_selectedBrand = widget.lead.brand;")) {
        content = content.replace(
            "super.initState();",
            "super.initState();\n    _selectedBrand = widget.lead.brand;\n    _selectedLocation = widget.lead.location;"
        );
        modified = true;
    }

    if (!content.includes("Widget _buildDropdownField(")) {
        // Find the last closing brace of the State class
        const parts = content.split("}");
        parts[parts.length - 2] = parts[parts.length - 2] + helperMethod;
        content = parts.join("}");
        modified = true;
    }

    // Replace the old UI
    const oldUIStart = "            // Send WhatsApp Message";
    const oldUIEnd = "            const SizedBox(height: 24),";
    if (content.includes(oldUIStart) && !content.includes("if (_sendWhatsappMessage) ...[")) {
        const regex = /            \/\/ Send WhatsApp Message[\s\S]*?            const SizedBox\(height: 24\),/;
        content = content.replace(regex, dropdownUI + "\n\n            const SizedBox(height: 24),");
        modified = true;
    }

    // Update the API logic
    if (content.includes("brand: widget.lead.brand ?? 'Unknown',")) {
        content = content.replace(
            "brand: widget.lead.brand ?? 'Unknown',",
            "brand: _selectedBrand ?? widget.lead.brand ?? 'Unknown',"
        );
        modified = true;
    }

    if (modified) {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log('Updated ' + file);
    }
}
