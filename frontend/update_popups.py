import os
import glob

directory = r'c:\flutter_apps\telecaller_app\frontend\lib\widgets.dart'
files = glob.glob(os.path.join(directory, 'incoming_call_*_popup_sheet.dart'))

checkbox_ui = '''            const SizedBox(height: 16),

            // Send WhatsApp Message
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

            const SizedBox(height: 24),

            // Buttons'''

api_logic = '''
      if (_sendWhatsappMessage) {
        final apiService = ApiService();
        await apiService.sendBrochureTemplate(
          customerPhone: widget.lead.phone ?? '',
          customerName: widget.lead.name.isEmpty ? 'Customer' : widget.lead.name,
          brand: widget.lead.brand ?? 'Unknown',
        );
      }
    } catch (e) {'''

for file_path in files:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    modified = False
    
    if "import 'package:telecaller_app/services/api_service.dart';" not in content:
        content = content.replace(
            "import 'package:telecaller_app/model/lead_model.dart';",
            "import 'package:telecaller_app/model/lead_model.dart';\nimport 'package:telecaller_app/services/api_service.dart';"
        )
        modified = True
        
    if "bool _sendWhatsappMessage = false;" not in content:
        content = content.replace(
            "bool _isSaving = false;",
            "bool _isSaving = false;\n  bool _sendWhatsappMessage = false;"
        )
        modified = True
        
    if "_sendWhatsappMessage" not in content.split("try {")[1] if "try {" in content else content:
        content = content.replace(
            "    } catch (e) {",
            api_logic
        )
        modified = True
        
    if "Send WhatsApp Message" not in content:
        content = content.replace(
            "            // Buttons",
            checkbox_ui
        )
        modified = True
        
    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Updated {os.path.basename(file_path)}')
