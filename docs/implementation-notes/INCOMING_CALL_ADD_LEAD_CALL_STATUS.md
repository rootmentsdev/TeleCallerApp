# Incoming Call - Add New Lead with Call Status

## Changes Made

### 1. Added Call Status Field to AddLeadBottomSheet
- **File**: `frontend/lib/widgets.dart/add_lead_bottom_sheet.dart`
- **Added Variables**:
  - `String? _selectedCallStatus` - Stores selected call status
  - `DateTime? _followUpDate` - Stores follow-up date when needed

### 2. Call Status Options
When adding a new lead from incoming call, users can now select:
- ✅ Connected
- ✅ Not Connected
- ✅ Interested
- ✅ Not Interested
- ✅ Forwarded

### 3. Follow-up Date Picker
- Shows automatically when "Not Connected" or "Interested" is selected
- Allows user to pick a follow-up date
- Hidden for other statuses

### 4. Smart Navigation Logic
**When user selects "Interested" or "Not Connected":**
1. Lead is saved to the database
2. FollowupDetailScreen opens automatically
3. Lead data is prefilled in the followup screen
4. User can immediately update the lead with closing action and remarks

**For other statuses:**
- Lead is saved
- Bottom sheet closes
- Returns to normal flow

## User Flow

### Incoming Call → Add New Lead → Call Status Selection

```
Incoming Call
    ↓
Check Phone API
    ↓
Lead doesn't exist → Show NewLeadPopupSheet
    ↓
User selects "Add Enquiry" or "Add Booked"
    ↓
AddLeadBottomSheet opens with:
  - Phone number (prefilled)
  - Call duration (prefilled)
  - Lead type selector
  - Customer name
  - NEW: Call Status dropdown ← NEW FEATURE
  - NEW: Follow-up date picker (conditional) ← NEW FEATURE
  - Store/Location
  - Other fields...
    ↓
User selects Call Status
    ↓
IF "Interested" or "Not Connected":
  - Show follow-up date picker
  - User picks date
  - User clicks "Save Lead"
  - Lead is created
  - FollowupDetailScreen opens automatically ← DIRECT NAVIGATION
  - User can update closing action and remarks
    ↓
ELSE (Connected, Not Connected, Forwarded, Not Interested):
  - User clicks "Save Lead"
  - Lead is created
  - Bottom sheet closes
  - Returns to normal flow
```

## Files Modified
- `frontend/lib/widgets.dart/add_lead_bottom_sheet.dart`
  - Added call status dropdown field
  - Added follow-up date picker (conditional)
  - Added import for FollowupDetailScreen
  - Modified _saveLead() to navigate to FollowupDetailScreen when appropriate

## Expected Behavior

### Scenario 1: User selects "Interested"
1. Call Status dropdown shows options
2. User selects "Interested"
3. Follow-up date picker appears
4. User picks a date
5. User clicks "Save Lead"
6. Lead is saved
7. FollowupDetailScreen opens with the lead data
8. User can update closing action and remarks
9. User clicks "Save Call Update"

### Scenario 2: User selects "Connected"
1. User selects "Connected"
2. No follow-up date picker shown
3. User clicks "Save Lead"
4. Lead is saved
5. Bottom sheet closes
6. Returns to normal flow

## Testing
1. Receive an incoming call
2. Phone doesn't exist in system
3. NewLeadPopupSheet shows
4. Click "Add Enquiry"
5. AddLeadBottomSheet opens
6. Select "Interested" from Call Status dropdown
7. Follow-up date picker should appear
8. Pick a date
9. Click "Save Lead"
10. FollowupDetailScreen should open automatically with the lead data
