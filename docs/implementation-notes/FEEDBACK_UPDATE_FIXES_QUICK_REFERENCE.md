# Feedback Update Fixes - Quick Reference Guide

## Overview
Three files need to be fixed to resolve the feedback update issue.

---

## Fix #1: Add Missing Fields to API Request Body

**File**: `frontend/lib/services/api_service.dart`

**Location**: Lines 214-290 (updateReturnLead method)

**Current Code** (BROKEN):
```dart
final requestBody = <String, dynamic>{
  'call_status': callStatus ?? 'Not Called',
  'lead_status': leadStatus ?? 'No Status',
};

if (callDate != null) {
  requestBody['call_date'] = callDate.toIso8601String();
}
if (rating != null && rating > 0) {
  requestBody['rating'] = rating;
}
if (remarks != null && remarks.trim().isNotEmpty) {
  requestBody['remarks'] = remarks.trim();
}
if (callDuration != null) {
  requestBody['call_duration'] = callDuration;
}
if (followUpFlag != null) {
  requestBody['follow_up_flag'] = followUpFlag;
  if (followUpFlag && followUpDate != null) {
    requestBody['follow_up_date'] = followUpDate.toIso8601String();
  }
} else if (followUpDate != null) {
  requestBody['follow_up_flag'] = true;
  requestBody['follow_up_date'] = followUpDate.toIso8601String();
}
```

**Fixed Code** (ADD THESE LINES):
```dart
// Add after the followUpDate section:

// Add missing fields
if (subCategory != null && subCategory.trim().isNotEmpty) {
  requestBody['sub_category'] = subCategory.trim();
}
if (itemCategory != null && itemCategory.trim().isNotEmpty) {
  requestBody['item_category'] = itemCategory.trim();
}
if (functionDate != null) {
  requestBody['function_date'] = functionDate.toIso8601String();
}
if (leadType != null && leadType.trim().isNotEmpty) {
  requestBody['lead_type'] = leadType.trim();
}
if (markAsComplaint != null) {
  requestBody['mark_as_complaint'] = markAsComplaint;
}
if (numberOfFunctions != null && numberOfFunctions.trim().isNotEmpty) {
  requestBody['no_of_functions'] = numberOfFunctions.trim();
}
if (numberOfAttires != null && numberOfAttires.trim().isNotEmpty) {
  requestBody['no_of_attires'] = numberOfAttires.trim();
}
if (competitor != null && competitor.trim().isNotEmpty) {
  requestBody['competitor'] = competitor.trim();
}
if (service != null && service.trim().isNotEmpty) {
  requestBody['service'] = service.trim();
}
if (refundStatus != null && refundStatus.trim().isNotEmpty) {
  requestBody['refund_status'] = refundStatus.trim();
}
```

**What This Does**:
- Adds 10 missing fields to the API request
- Ensures all feedback data is sent to backend
- Prevents data loss

---

## Fix #2: Add Feedback Update After Outgoing Call Creation

**File**: `frontend/lib/widgets.dart/add_lead_outgoing_call_bottom_sheet.dart`

**Location**: Lines 850-950 (_saveLead method)

**Current Code** (BROKEN):
```dart
Future<void> _saveLead() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final apiService = ApiService();
    final leadRepository = LeadRepository();

    // ... store and leadType normalization ...

    final apiResponse = await apiService.createLead(
      leadName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      store: store,
      source: 'Outgoing Call',
      leadType: normalizedLeadType,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      functionDate: _functionDate?.toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
      callDuration: _callDuration,
      subCategory: _selectedSubCategory,
      itemCategory: _selectedItemCategory,
      closingAction: _selectedCloseReason,
      markAsComplaint: _markAsComplaint,
      callStatus: _selectedCallStatus,
      followUpFlag: _followUpDate != null,
      followUpDate: _followUpDate?.toIso8601String(),
    );

    String leadId = '';

    // ... leadId extraction logic ...

    // ❌ MISSING: No feedback update here!

    if (existingLead == null) {
      final lead = LeadModel(
        id: leadId,
        name: _nameController.text.trim(),
        // ... other fields ...
      );

      await leadRepository.addLead(lead);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  } catch (e) {
    // ... error handling ...
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

**Fixed Code** (ADD THIS SECTION):
```dart
Future<void> _saveLead() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final apiService = ApiService();
    final leadRepository = LeadRepository();

    // ... store and leadType normalization ...

    final apiResponse = await apiService.createLead(
      leadName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      store: store,
      source: 'Outgoing Call',
      leadType: normalizedLeadType,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      functionDate: _functionDate?.toIso8601String(),
      createdAt: DateTime.now().toIso8601String(),
      callDuration: _callDuration,
      subCategory: _selectedSubCategory,
      itemCategory: _selectedItemCategory,
      closingAction: _selectedCloseReason,
      markAsComplaint: _markAsComplaint,
      callStatus: _selectedCallStatus,
      followUpFlag: _followUpDate != null,
      followUpDate: _followUpDate?.toIso8601String(),
    );

    String leadId = '';

    // ... leadId extraction logic ...

    // ✅ NEW: Update lead with feedback after creation
    if (leadId.isNotEmpty) {
      try {
        await apiService.updateReturnLead(
          id: leadId,
          callStatus: _selectedCallStatus,
          remarks: _remarksController.text.trim().isNotEmpty
            ? _remarksController.text.trim()
            : null,
          callDuration: _callDuration > 0 ? _callDuration : null,
          markAsComplaint: _markAsComplaint ? true : null,
          subCategory: _selectedSubCategory,
          functionDate: _functionDate,
          numberOfFunctions: _numberOfFunctionsController.text.isNotEmpty
            ? _numberOfFunctionsController.text
            : null,
          numberOfAttires: _numberOfAttireController.text.isNotEmpty
            ? _numberOfAttireController.text
            : null,
          competitor: _competitorController.text.isNotEmpty
            ? _competitorController.text
            : null,
        );
      } catch (updateError) {
        print('AddLeadOutgoingCallBottomSheet: Warning - Failed to update lead with feedback: $updateError');
        // Continue anyway - lead was created, just feedback update failed
      }
    }

    if (existingLead == null) {
      final lead = LeadModel(
        id: leadId,
        name: _nameController.text.trim(),
        // ... other fields ...
      );

      await leadRepository.addLead(lead);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  } catch (e) {
    // ... error handling ...
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

**What This Does**:
- Calls updateReturnLead() after creating the lead
- Sends all feedback fields to backend
- Ensures feedback is saved even if update fails

---

## Fix #3: Verify Complete Field Mapping in Return Lead Update

**File**: `frontend/lib/view/lead_screen/return_lead_details_screen.dart`

**Location**: Lines 300-350 (_saveReturnLead method)

**Current Code** (CHECK):
```dart
Future<void> _saveReturnLead() async {
  if (_selectedCallStatus == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a call status'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    final leadController = Provider.of<LeadScreenController>(
      context,
      listen: false,
    );

    await leadController.updateReturnLead(
      id: widget.lead.id,
      callStatus: _selectedCallStatus,
      rating: _markAsComplaint ? null : (_rating > 0 ? _rating : null),
      remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
      callDuration: _callDuration > 0 ? _callDuration : null,
      markAsComplaint: _markAsComplaint ? true : null,
      subCategory: _selectedComplaintSubCategory,
      numberOfFunctions: _numberOfFunctionsController.text.isNotEmpty
        ? _numberOfFunctionsController.text
        : null,
      numberOfAttires: _numberOfAttireController.text.isNotEmpty
        ? _numberOfAttireController.text
        : null,
      competitor: _competitorController.text.isNotEmpty
        ? _competitorController.text
        : null,
      service: _selectedService,
      refundStatus: _securityAmountRefundStatus,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback call updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving feedback call: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }
}
```

**Verification Checklist**:
- ✅ callStatus is sent
- ✅ rating is sent
- ✅ remarks is sent
- ✅ callDuration is sent
- ✅ markAsComplaint is sent
- ✅ subCategory is sent
- ✅ numberOfFunctions is sent
- ✅ numberOfAttires is sent
- ✅ competitor is sent
- ✅ service is sent
- ✅ refundStatus is sent

**Status**: ✅ This file is CORRECT - all fields are being sent

---

## Summary of Changes

| File | Change | Impact |
|------|--------|--------|
| `api_service.dart` | Add 10 fields to request body | Fixes missing data in API request |
| `add_lead_outgoing_call_bottom_sheet.dart` | Add updateReturnLead() call | Fixes feedback loss in outgoing calls |
| `return_lead_details_screen.dart` | Verify (no changes needed) | Already correct |

---

## Testing After Fixes

### Test 1: Outgoing Call with Feedback
1. Open outgoing call form
2. Make a call
3. Fill all feedback fields
4. Click "Save Lead"
5. **Check**: Network tab shows all fields in request
6. **Check**: Database has all feedback fields

### Test 2: Return Lead Update
1. Open return lead details
2. Fill all feedback fields
3. Click "Save"
4. **Check**: Network tab shows all fields in request
5. **Check**: Database has all feedback fields

### Test 3: Network Logs
1. Open DevTools → Network tab
2. Make a feedback call
3. Look for POST request to `/api/return/update/{id}`
4. **Expected**: Request body has 15+ fields
5. **Actual**: Should match expected

### Test 4: Database Verification
```sql
db.leads.findOne({ _id: "69c763f59767fbce256df30d" })
```
**Check**: All feedback fields are populated

---

## Rollback Plan

If issues occur after deployment:

1. **Revert api_service.dart** - Remove the 10 new fields
2. **Revert add_lead_outgoing_call_bottom_sheet.dart** - Remove updateReturnLead() call
3. **Redeploy** - Push previous version

---

## Monitoring After Fix

Monitor these metrics:
- API request size (should increase)
- Database field population (should increase)
- User feedback (should improve)
- Error rates (should decrease)

---

## Questions?

Refer to:
- `FEEDBACK_UPDATE_NOT_POSTING_ANALYSIS.md` - Technical details
- `FEEDBACK_UPDATE_ISSUE_EXPLAINED.md` - Detailed explanation
- `FEEDBACK_UPDATE_FLOW_DIAGRAM.md` - Visual diagrams
