const fs = require('fs');
const path = require('path');

const directory = 'c:\\flutter_apps\\telecaller_app\\frontend\\lib\\widgets.dart';

const files = [
    'add_lead_bottom_sheet.dart',
    'add_lead_outgoing_call_bottom_sheet.dart',
    'incoming_call_report_popup_sheet.dart',
    'incoming_call_followup_popup_sheet.dart',
    'incoming_call_justdial_popup_sheet.dart'
];

const validationCode = `    if (_sendWhatsappMessage && (_selectedBrand == null || _selectedLocation == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Store and Location to send WhatsApp message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }`;

for (const file of files) {
    const filePath = path.join(directory, file);
    if (!fs.existsSync(filePath)) {
        console.log('File not found: ' + file);
        continue;
    }
    
    let content = fs.readFileSync(filePath, 'utf8');
    let modified = false;

    if (file.includes('add_lead')) {
        // Find _saveLead() async {
        if (!content.includes("Please select Store and Location")) {
            content = content.replace(
                "    if (!_formKey.currentState!.validate()) {\n      return;\n    }",
                "    if (!_formKey.currentState!.validate()) {\n      return;\n    }\n\n" + validationCode
            );
            modified = true;
        }
    } else {
        // For the popup sheets
        if (!content.includes("Please select Store and Location")) {
            // we want to put it at the beginning of _handleSave
            // usually starts with:
            // Future<void> _handleSave() async {
            //   if (_selectedClosingAction == null) { ... } -> for followup
            //   setState(() => _isSaving = true);
            
            if (content.includes("    setState(() => _isSaving = true);")) {
                content = content.replace(
                    "    setState(() => _isSaving = true);",
                    validationCode + "\n\n    setState(() => _isSaving = true);"
                );
                modified = true;
            }
        }
    }

    if (modified) {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log('Updated ' + file);
    }
}
