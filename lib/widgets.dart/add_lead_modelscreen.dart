import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/add_lead_controller.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';

class AddLeadBottomSheet extends StatelessWidget {
  const AddLeadBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddLeadController(),
      child: const _AddLeadBottomSheetContent(),
    );
  }
}

class _AddLeadBottomSheetContent extends StatefulWidget {
  const _AddLeadBottomSheetContent();

  @override
  State<_AddLeadBottomSheetContent> createState() =>
      _AddLeadBottomSheetContentState();
}

class _AddLeadBottomSheetContentState
    extends State<_AddLeadBottomSheetContent> {
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AddLeadController>(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                "Add New Leads",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: TextConstant.dmSansBold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller.nameController,
                decoration: InputDecoration(
                  hintText: "Customer Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  prefixIcon: const Icon(Icons.person_3_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Phone Number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 10),
              // Grid of Dropdowns (2x2)
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      context: context,
                      controller: controller,
                      hint: "Brand",
                      value: controller.selectedBrand,
                      items: controller.brands,
                      onChanged: (value) {
                        controller.setSelectedBrand(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      context: context,
                      controller: controller,
                      hint:
                          controller.selectedBrand == null
                              ? "Select Brand First"
                              : "Location",
                      value: controller.selectedLocation,
                      items: controller.locations,
                      enabled: controller.selectedBrand != null,
                      onChanged:
                          controller.selectedBrand != null
                              ? (value) {
                                controller.setSelectedLocation(value);
                              }
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      context: context,
                      controller: controller,
                      hint: "Lead Status",
                      value: controller.selectedLeadStatus,
                      items: controller.leadStatuses,
                      onChanged: (value) {
                        controller.setSelectedLeadStatus(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownField(
                      context: context,
                      controller: controller,
                      hint: "Call Status",
                      value: controller.selectedCallStatus,
                      items: controller.callStatuses,
                      onChanged: (value) {
                        controller.setSelectedCallStatus(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: controller.followUpDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    controller.setFollowUpDate(pickedDate);
                  }
                },
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: ColorConstant.grey),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.followUpDate != null
                              ? "Follow-Up Date: ${_formatDate(controller.followUpDate!)}"
                              : "Follow-Up Date (Optional)",
                          style: TextStyle(
                            color:
                                controller.followUpDate != null
                                    ? Colors.black87
                                    : Colors.grey[700],
                          ),
                        ),
                        const Icon(Icons.calendar_month),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await controller.submitLead();
                        if (!mounted) return;

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                controller.followUpDate != null
                                    ? 'Lead added successfully! Follow-up scheduled.'
                                    : 'Lead added successfully!',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter customer name and phone number',
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: ColorConstant.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Submit",
                        style: TextStyle(
                          color: Colors.white,
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
      ),
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required AddLeadController controller,
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?)? onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
        ),
        borderRadius: BorderRadius.circular(12),
        color: enabled ? Colors.transparent : Colors.grey[100],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: enabled ? Colors.grey[700] : Colors.grey[400],
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: enabled ? Colors.grey[700] : Colors.grey[400],
          ),
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: enabled ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                );
              }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}
