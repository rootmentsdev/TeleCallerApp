# Follow-Up API Fix Implementation Checklist

## Overview
This checklist tracks the implementation of missing Follow-Up API fields and routing logic.

---

## Phase 1: LeadModel Updates
**File:** `frontend/lib/model/lead_model.dart`

### GET Response Fields to Add
- [ ] `DateTime? enquiryDate` - From enquiry_date
- [ ] `DateTime? functionDate` - From function_date
- [ ] `DateTime? visitDate` - From visit_date
- [ ] `String? bookingNumber` - From booking_number
- [ ] `DateTime? returnDate` - From return_date
- [ ] `Map<String, dynamic>? assignedTo` - From assigned_to

### POST Request Fields to Add
- [ ] `bool? followUpFlag` - Controls routing to Follow-Ups
- [ ] `bool? markAsComplaint` - Controls routing to Complaints
- [ ] `int? rating` - Rating for Return leads
- [ ] `String? subCategory` - Sub-category
- [ ] `String? closingAction` - Closing action
- [ ] `String? leadType` - Lead type
- [ ] `DateTime? functionDate` - Function date

### Constructor Updates
- [ ] Add all new fields to constructor
- [ ] Add all new fields to copyWith method
- [ ] Add all new fields to fromJson method
- [ ] Add all new fields to toJson method

### Validation
- [ ] Run `flutter analyze` - No errors
- [ ] Check for null safety issues
- [ ] Verify all fields are properly typed

---

## Phase 2: API Service Updates
**File:** `frontend/lib/services/api_service.dart`

### postFollowUp Method Signature
- [ ] Add `bool? followUpFlag` parameter
- [ ] Add `bool? markAsComplaint` parameter
- [ ] Add `String? subCategory` parameter
- [ ] Add `String? closingAction` parameter
- [ ] Add `int? rating` parameter
- [ ] Add `String? leadType` parameter
- [ ] Add `DateTime? functionDate` parameter

### Request Body Construction
- [ ] Add follow_up_flag to request body
- [ ] Add mark_as_complaint to request body
- [ ] Add sub_category to request body
- [ ] Add closing_action to request body
- [ ] Add rating to request body
- [ ] Add lead_type to request body
- [ ] Add function_date to request body

### Conditional Logic
- [ ] Only include fields if not null
- [ ] Handle follow_up_flag + follow_up_date together
- [ ] Validate date formats (ISO 8601)
- [ ] Trim string fields

### Logging
- [ ] Add logging for new fields
- [ ] Log request body before sending
- [ ] Log response status and body

### Validation
- [ ] Run `flutter analyze` - No errors
- [ ] Verify all parameters are used
- [ ] Check error handling

---

## Phase 3: Lead Repository Updates
**File:** `frontend/lib/controller/lead_repository.dart`

### updateFollowUpLeadFromApi Method Signature
- [ ] Add `bool? followUpFlag` parameter
- [ ] Add `bool? markAsComplaint` parameter
- [ ] Add `String? subCategory` parameter
- [ ] Add `String? closingAction` parameter
- [ ] Add `int? rating` parameter
- [ ] Add `String? leadType` parameter
- [ ] Add `DateTime? functionDate` parameter

### API Service Call
- [ ] Pass all new parameters to postFollowUp
- [ ] Verify parameter mapping

### Local Lead Update
- [ ] Update followUpFlag field
- [ ] Update markAsComplaint field
- [ ] Update subCategory field
- [ ] Update closingAction field
- [ ] Update rating field
- [ ] Update leadType field
- [ ] Update functionDate field

### Error Handling
- [ ] Catch and log errors
- [ ] Re-throw exceptions
- [ ] Handle null responses

### Validation
- [ ] Run `flutter analyze` - No errors
- [ ] Verify all fields are updated

---

## Phase 4: Lead Screen Controller Updates
**File:** `frontend/lib/controller/lead_screen_controller.dart`

### updateFollowUpLead Method Signature
- [ ] Add `bool? followUpFlag` parameter
- [ ] Add `bool? markAsComplaint` parameter
- [ ] Add `String? subCategory` parameter
- [ ] Add `String? closingAction` parameter
- [ ] Add `int? rating` parameter
- [ ] Add `String? leadType` parameter
- [ ] Add `DateTime? functionDate` parameter

### Repository Call
- [ ] Pass all new parameters to updateFollowUpLeadFromApi
- [ ] Verify parameter mapping

### State Management
- [ ] Call _removeLeadFromActiveLists
- [ ] Call notifyListeners
- [ ] Handle errors with Crashlytics

### Validation
- [ ] Run `flutter analyze` - No errors
- [ ] Verify all parameters are passed

---

## Phase 5: Follow-Up Detail Screen Updates
**File:** `frontend/lib/view/followup_detail_screen.dart`

### State Variables
- [ ] Add `bool _markAsFollowUp` (if not exists)
- [ ] Add `bool _markAsComplaint` (if not exists)
- [ ] Add `String? _selectedSubCategory` (if not exists)
- [ ] Add `String? _selectedLeadStatus` (if not exists)
- [ ] Add `int _rating` (if not exists)

### UI Components
- [ ] Add "Mark as Follow-Up" checkbox (if needed)
- [ ] Add "Mark as Complaint" checkbox (if needed)
- [ ] Add Sub Category dropdown (if needed)
- [ ] Add Lead Status dropdown (if needed)
- [ ] Add Rating stars (if needed)

### Routing Logic
- [ ] Implement follow_up_flag logic
- [ ] Implement mark_as_complaint logic
- [ ] Verify routing precedence:
  - [ ] mark_as_complaint takes priority
  - [ ] follow_up_flag is secondary
  - [ ] Default is Reports

### Save Method
- [ ] Determine followUpFlag value
- [ ] Determine markAsComplaint value
- [ ] Pass all parameters to controller
- [ ] Handle success response
- [ ] Handle error response

### Code Example
```dart
// Determine routing
bool? followUpFlag;
bool? markAsComplaint;

if (_markAsComplaint) {
  markAsComplaint = true;
  followUpFlag = false;
} else if (_markAsFollowUp) {
  followUpFlag = true;
  markAsComplaint = false;
} else {
  followUpFlag = false;
  markAsComplaint = false;
}

await leadController.updateFollowUpLead(
  id: widget.lead.id,
  callStatus: _selectedClosingAction,
  leadStatus: _selectedLeadStatus,
  remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
  callDuration: _callDuration > 0 ? _callDuration : null,
  followUpFlag: followUpFlag,
  markAsComplaint: markAsComplaint,
  subCategory: _selectedSubCategory,
  closingAction: _selectedClosingAction,
  rating: _rating > 0 ? _rating : null,
);
```

### Validation
- [ ] Run `flutter analyze` - No errors
- [ ] Check for null safety issues

---

## Phase 6: Testing

### Unit Tests
- [ ] Test LeadModel with new fields
- [ ] Test API service with new parameters
- [ ] Test repository with new parameters
- [ ] Test controller with new parameters

### Integration Tests
- [ ] Test complete flow with mark_as_complaint = true
- [ ] Test complete flow with follow_up_flag = true
- [ ] Test complete flow with both false (default)
- [ ] Test error handling

### Manual Testing
- [ ] [ ] Test Scenario 1: Mark as Complaint
  - [ ] Select "Mark as Complaint"
  - [ ] Click Save
  - [ ] Verify lead moves to Complaints
  - [ ] Check API request includes mark_as_complaint: true

- [ ] [ ] Test Scenario 2: Keep in Follow-Ups
  - [ ] Select "Mark as Follow-Up"
  - [ ] Select follow-up date
  - [ ] Click Save
  - [ ] Verify lead stays in Follow-Ups
  - [ ] Check API request includes follow_up_flag: true

- [ ] [ ] Test Scenario 3: Complete (Default)
  - [ ] Don't select any follow-up option
  - [ ] Click Save
  - [ ] Verify lead moves to Reports
  - [ ] Check API request includes follow_up_flag: false

- [ ] [ ] Test with all optional fields
  - [ ] Fill in sub-category
  - [ ] Fill in closing action
  - [ ] Fill in rating
  - [ ] Verify all fields are sent in request

- [ ] [ ] Test error handling
  - [ ] Test with invalid data
  - [ ] Test with network error
  - [ ] Verify error message is shown

### Regression Testing
- [ ] Verify existing functionality still works
- [ ] Test other lead types (Return, Loss of Sale, etc.)
- [ ] Test list view updates correctly
- [ ] Test detail view displays correctly

---

## Phase 7: Code Review

### Code Quality
- [ ] No unused variables
- [ ] No unused imports
- [ ] Consistent naming conventions
- [ ] Proper error handling
- [ ] Null safety compliance

### Documentation
- [ ] Add comments for new fields
- [ ] Update method documentation
- [ ] Add routing logic explanation
- [ ] Update API documentation

### Performance
- [ ] No unnecessary rebuilds
- [ ] No memory leaks
- [ ] Efficient API calls
- [ ] Proper state management

---

## Phase 8: Deployment

### Pre-Deployment
- [ ] All tests passing
- [ ] No analyzer warnings
- [ ] Code review approved
- [ ] Documentation updated

### Deployment
- [ ] Build APK/IPA
- [ ] Test on device
- [ ] Verify API calls
- [ ] Monitor for errors

### Post-Deployment
- [ ] Monitor error logs
- [ ] Verify user feedback
- [ ] Check API metrics
- [ ] Document any issues

---

## Summary Checklist

### Critical Items (Must Complete)
- [ ] Add follow_up_flag to POST request
- [ ] Add mark_as_complaint to POST request
- [ ] Implement routing logic
- [ ] Test all routing scenarios

### Important Items (Should Complete)
- [ ] Add all optional fields to POST request
- [ ] Update LeadModel with new fields
- [ ] Add UI for new fields
- [ ] Complete integration testing

### Nice to Have (Can Complete Later)
- [ ] Map all GET response fields
- [ ] Add comprehensive documentation
- [ ] Add unit tests
- [ ] Performance optimization

---

## Progress Tracking

| Phase | Status | Completion | Notes |
|-------|--------|-----------|-------|
| 1. LeadModel | ⬜ | 0% | |
| 2. API Service | ⬜ | 0% | |
| 3. Repository | ⬜ | 0% | |
| 4. Controller | ⬜ | 0% | |
| 5. UI Screen | ⬜ | 0% | |
| 6. Testing | ⬜ | 0% | |
| 7. Code Review | ⬜ | 0% | |
| 8. Deployment | ⬜ | 0% | |

---

## Notes

- Start with Phase 1-4 (backend changes)
- Then implement Phase 5 (UI changes)
- Thoroughly test Phase 6
- Get code review in Phase 7
- Deploy in Phase 8

**Estimated Time:** 2-3 hours

**Priority:** CRITICAL - Fixes entire follow-up workflow
