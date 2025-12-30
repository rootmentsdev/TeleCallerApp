import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/followup_controller.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/services/phone_call_service.dart';
import 'package:telecaller_app/utils/format_helper.dart';

class FollowUpDetailsScreen extends StatefulWidget {
  final LeadModel followUpLead;

  const FollowUpDetailsScreen({super.key, required this.followUpLead});

  @override
  State<FollowUpDetailsScreen> createState() => _FollowUpDetailsScreenState();
}

class _FollowUpDetailsScreenState extends State<FollowUpDetailsScreen> {
  String? selectedCallStatus;
  String? selectedLeadStatus;
  int rating = 0;
  final TextEditingController remarksController = TextEditingController();

  bool _isCallActive = false;
  int _callDurationSeconds = 0;
  bool _hasCalled = false;
  bool _isWaitingForDuration = false;
  bool _isSaving = false;

  final List<String> callStatusOptions = [
    "Not called yet",
    "Connected",
    "Not Connected",
    "Call Back Later",
    "Confirmed",
    "Cancelled",
  ];

  final List<String> leadStatusOptions = [
    "No Status",
    "Confirmed",
    "Pending",
    "Cancelled",
    "Follow Up Required",
  ];

  @override
  void initState() {
    super.initState();
    print(
      '[FollowUpDetailsScreen] initState called for lead: ${widget.followUpLead.name}',
    );
    print('[FollowUpDetailsScreen] Lead ID: ${widget.followUpLead.id}');
    print('[FollowUpDetailsScreen] Lead phone: ${widget.followUpLead.phone}');

    PhoneCallService.initialize(
      onCallEnded: (phoneNumber, duration) {
        print('[FollowUpDetailsScreen] onCallEnded callback triggered');
        print(
          '[FollowUpDetailsScreen] Phone: $phoneNumber, Duration: $duration seconds',
        );
        if (mounted && duration != null && duration > 0) {
          print('[FollowUpDetailsScreen] Duration is valid: $duration > 0');
          setState(() {
            _callDurationSeconds = duration;
            _isCallActive = false;
            _isWaitingForDuration = false;
            _hasCalled = true;
            if (selectedCallStatus == null) {
              selectedCallStatus = "Connected";
            }
          });
          print(
            '[FollowUpDetailsScreen] State updated: _callDurationSeconds=$_callDurationSeconds, _hasCalled=$_hasCalled',
          );
        } else {
          print(
            '[FollowUpDetailsScreen] Duration invalid or not mounted: duration=$duration, mounted=$mounted',
          );
        }
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      print('[FollowUpDetailsScreen] Phone number is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    print(
      '[FollowUpDetailsScreen] Making call to: $cleanedNumber (original: $phoneNumber)',
    );

    try {
      final success = await PhoneCallService.makeCall(cleanedNumber);
      print('[FollowUpDetailsScreen] Call initiated, success: $success');
      if (success && mounted) {
        setState(() {
          _isCallActive = true;
          _callDurationSeconds = 0;
          _hasCalled = true;
        });
        print(
          '[FollowUpDetailsScreen] UI state updated: _isCallActive=true, _hasCalled=true',
        );
      }
    } catch (e) {
      print('[FollowUpDetailsScreen] Error making call: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error making call: $e')));
    }
  }

  Future<void> _saveFollowUpUpdate() async {
    if (!_hasCalled) {
      print('[FollowUpDetailsScreen] Save attempted but no call made');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please call the lead first')),
      );
      return;
    }

    print('[FollowUpDetailsScreen] Saving follow-up update');
    print('[FollowUpDetailsScreen] Lead ID: ${widget.followUpLead.id}');
    print('[FollowUpDetailsScreen] Call Status: $selectedCallStatus');
    print('[FollowUpDetailsScreen] Lead Status: $selectedLeadStatus');
    print(
      '[FollowUpDetailsScreen] Call Duration: $_callDurationSeconds seconds',
    );
    print('[FollowUpDetailsScreen] Remarks: ${remarksController.text}');
    print('[FollowUpDetailsScreen] Rating: $rating');

    setState(() => _isSaving = true);

    try {
      final followupController = Provider.of<FollowupController>(
        context,
        listen: false,
      );

      print('[FollowUpDetailsScreen] Calling updateFollowUpLead...');
      await followupController.updateFollowUpLead(
        id: widget.followUpLead.id,
        callStatus: selectedCallStatus ?? "Connected",
        leadStatus: selectedLeadStatus,
        remarks: remarksController.text.trim(),
        callDuration: _callDurationSeconds > 0 ? _callDurationSeconds : null,
        rating: rating > 0 ? rating : null,
      );

      print(
        '[FollowUpDetailsScreen] updateFollowUpLead completed successfully',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Follow-up updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            print('[FollowUpDetailsScreen] Popping screen');
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      print('[FollowUpDetailsScreen] Error saving follow-up: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Follow-Up Details'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lead Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.followUpLead.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.followUpLead.phone),
                    const SizedBox(height: 8),
                    if (widget.followUpLead.followUpDate != null)
                      Text(
                        'Follow-up Date: ${widget.followUpLead.followUpDate!.toString().split(' ')[0]}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Call Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isCallActive
                        ? null
                        : () => _makePhoneCall(widget.followUpLead.phone),
                icon: Icon(_isCallActive ? Icons.phone_disabled : Icons.phone),
                label: Text(_isCallActive ? 'Calling...' : 'Call Now'),
              ),
            ),
            const SizedBox(height: 24),

            // Call Duration Display
            if (_isWaitingForDuration || _callDurationSeconds > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      _isWaitingForDuration
                          ? Colors.blue[50]
                          : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _isWaitingForDuration
                            ? Colors.blue[300]!
                            : Colors.green[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isWaitingForDuration
                          ? Icons.hourglass_empty
                          : Icons.timer,
                      color: _isWaitingForDuration ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isWaitingForDuration
                                ? 'Reading Duration...'
                                : 'Call Duration',
                            style: TextStyle(
                              color:
                                  _isWaitingForDuration
                                      ? Colors.blue
                                      : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isWaitingForDuration
                                ? 'Writing to call log...'
                                : FormatHelper.formatCallDurationWithUnits(
                                  _callDurationSeconds,
                                ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Call Status Dropdown
            DropdownButtonFormField<String>(
              value: selectedCallStatus,
              hint: const Text('Select Call Status'),
              items:
                  callStatusOptions.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
              onChanged:
                  _hasCalled
                      ? (value) => setState(() => selectedCallStatus = value)
                      : null,
              decoration: InputDecoration(
                labelText: 'Call Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lead Status Dropdown
            DropdownButtonFormField<String>(
              value: selectedLeadStatus,
              hint: const Text('Select Lead Status'),
              items:
                  leadStatusOptions.map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
              onChanged:
                  _hasCalled
                      ? (value) => setState(() => selectedLeadStatus = value)
                      : null,
              decoration: InputDecoration(
                labelText: 'Lead Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Remarks
            TextField(
              controller: remarksController,
              enabled: _hasCalled,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Remarks',
                hintText: 'Enter remarks about the call',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _hasCalled && !_isSaving ? _saveFollowUpUpdate : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSaving
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Save Call Update'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }
}
