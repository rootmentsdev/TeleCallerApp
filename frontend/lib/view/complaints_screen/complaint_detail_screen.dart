import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/model/complaint_model.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ComplaintDetailScreen extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  bool _hasCalled = false;
  bool _hasSaved = false; // Track if complaint has been saved after call
  int _callDuration = 0;
  final TextEditingController _remarksController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill remarks: if call was made, use complaint_remarks, otherwise use original remarks
    if (widget.complaint.hasCallBeenMade && widget.complaint.complaintRemarks.isNotEmpty) {
      _remarksController.text = widget.complaint.complaintRemarks;
    } else {
      _remarksController.text = widget.complaint.remarks;
    }
    
    // Check if call was already made (from backend data)
    // If callStatus is not "Not Called" or callDuration > 0, call was already made
    if (widget.complaint.hasCallBeenMade) {
      _hasCalled = true;
      _hasSaved = true; // If call was made, it means it was already saved
      if (widget.complaint.callDuration != null && widget.complaint.callDuration! > 0) {
        _callDuration = widget.complaint.callDuration!;
      }
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callTrackingController = Provider.of<CallTrackingController>(
        context,
        listen: false,
      );
      callTrackingController.initialize();
      callTrackingController.addListener(_onCallDurationUpdate);
    });
  }

  void _onCallDurationUpdate() {
    final callTrackingController = Provider.of<CallTrackingController>(
      context,
      listen: false,
    );

    if (callTrackingController.lastDuration != null &&
        callTrackingController.lastDuration! > 0) {
      if (mounted) {
        setState(() {
          _callDuration = callTrackingController.lastDuration!;
        });
      }
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} Mins';
  }

  Future<void> _saveComplaint() async {
    // Validate that remarks are provided
    if (_remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complaint remarks'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Use complaint ID for the complaints call endpoint
      final complaintId = widget.complaint.id;
      
      // Make API call to POST complaint call data
      // Endpoint: /api/pages/complaints/{id}/call
      final url = Uri.parse('${ApiConfig.baseUrl}/api/pages/complaints/$complaintId/call');
      final apiService = ApiService();
      final headers = await apiService.getAuthHeaders();
      
      if (!headers.containsKey('Authorization')) {
        throw Exception('Authentication required. Please login again.');
      }
      
      // Prepare request body for complaint call endpoint
      final requestBody = <String, dynamic>{
        'remarks': _remarksController.text.trim(), // Complaint remarks
        'call_duration': _callDuration > 0 ? _callDuration : 0, // Call duration in seconds
        // Update call_status to indicate call was made
        // If call duration > 0, call was likely connected; otherwise use a default status
        'call_status': _callDuration > 0 ? 'Connected' : 'Not Connected',
      };
      
      final requestBodyJson = json.encode(requestBody);
      
      print('ComplaintDetailScreen: Patching complaint call data');
      print('ComplaintDetailScreen: PATCH URL: $url');
      print('ComplaintDetailScreen: PATCH BODY: $requestBodyJson');
      
      final response = await http.patch(
        url,
        headers: headers,
        body: requestBodyJson,
      );
      
      print('ComplaintDetailScreen: Response status: ${response.statusCode}');
      print('ComplaintDetailScreen: Response body: ${response.body}');
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        String errorMessage = 'Failed to update complaint: Status ${response.statusCode}';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['message'] ?? 
                          errorData['error'] ?? 
                          errorData['msg'] ?? 
                          errorMessage;
          }
        } catch (e) {
          print('ComplaintDetailScreen: Could not parse error response: $e');
        }
        throw Exception(errorMessage);
      }

      if (mounted) {
        // Mark as saved - this will hide "Call Now" button
        setState(() {
          _hasSaved = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Wait a moment to show success message, then go back
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Pop back to complaints screen
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate refresh needed
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving complaint: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 30, bottom: 10),
                    child: Text(
                      "Complaint Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Details Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6E6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.complaint.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE23434),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.complaint.type,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '+91 ${widget.complaint.phone}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Complaint Details Section
                    Text(
                      'Complaint Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        fontFamily: TextConstant.dmSansMedium,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Call Date with Duration Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complaint Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: TextConstant.dmSansRegular,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.complaint.date,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                        if (_callDuration > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE6E6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatDuration(_callDuration),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE23434),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Store and Function Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Store',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.complaint.store,
                                style: const TextStyle(
                                  fontSize: 13,
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
                                'Function Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.complaint.functionDate.isEmpty 
                                    ? 'N/A' 
                                    : widget.complaint.functionDate,
                                style: const TextStyle(
                                  fontSize: 13,
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

                    // Sub Category
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sub Category',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.complaint.subCategory.isEmpty 
                              ? 'Not specified' 
                              : widget.complaint.subCategory,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Current Remarks
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Remarks',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.complaint.hasCallBeenMade
                              ? (widget.complaint.complaintRemarks.isNotEmpty 
                                  ? widget.complaint.complaintRemarks 
                                  : 'No complaint remarks')
                              : (widget.complaint.remarks.isNotEmpty 
                                  ? widget.complaint.remarks 
                                  : 'No remarks'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Show "Call Now" button only if NOT called yet AND NOT saved
                    // Once saved (after call), hide the button
                    if (!_hasCalled && !_hasSaved)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _makeCall,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstant.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Call Now",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: TextConstant.dmSansMedium,
                            ),
                          ),
                        ),
                      )
                    // After call and save: Show completion message
                    else if (_hasSaved)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Complaint call saved successfully',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[700],
                                fontFamily: TextConstant.dmSansMedium,
                              ),
                            ),
                          ],
                        ),
                      )
                    // After call (but not saved yet): Show form
                    else if (_hasCalled && !_hasSaved) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Complaint Remarks",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              fontFamily: TextConstant.dmSansMedium,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _remarksController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "Enter your remarks",
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontFamily: TextConstant.dmSansRegular,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: ColorConstant.primaryColor,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: TextConstant.dmSansMedium,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveComplaint,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorConstant.primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      "Save Complaint",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: TextConstant.dmSansMedium,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _makeCall() async {
    try {
      final phoneNumber = widget.complaint.phone;
      await PhoneCallService.makeCall(phoneNumber);

      if (mounted) {
        setState(() {
          _hasCalled = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

