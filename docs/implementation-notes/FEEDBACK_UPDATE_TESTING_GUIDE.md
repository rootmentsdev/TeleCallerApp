# Feedback Update Fixes - Testing Guide

## Quick Test (5 minutes)

### Test 1: Verify API Request Has All Fields

**Steps**:
1. Open your app in browser
2. Open DevTools (F12)
3. Go to Network tab
4. Make an outgoing call with feedback
5. Fill in all feedback fields
6. Click "Save Lead"
7. Look for POST request to `/api/return/update/{id}`
8. Click on the request
9. Go to "Request" tab
10. Check the request body

**Expected Result**:
```json
{
  "call_status": "Connected",
  "lead_status": "No Status",
  "call_date": "2026-03-30T10:30:00Z",
  "rating": 5,
  "remarks": "Customer interested",
  "call_duration": 45,
  "follow_up_flag": false,
  "follow_up_date": null,
  "sub_category": "Product Enquiry",
  "item_category": "Suit",
  "function_date": "2026-04-10T00:00:00Z",
  "lead_type": "enquiry",
  "mark_as_complaint": false,
  "no_of_functions": "2",
  "no_of_attires": "5",
  "competitor": "XYZ Store",
  "service": "Excellent",
  "refund_status": "Security Amount Refunded"
}
```

**What to Check**:
- ✅ Should have 15+ fields
- ✅ All feedback fields should be present
- ✅ No fields should be missing

---

## Detailed Test (15 minutes)

### Test 2: Verify Feedback is Saved in Database

**Steps**:
1. Make an outgoing call with specific feedback
2. Note the phone number used
3. Open database client (MongoDB Compass, etc.)
4. Query the leads collection
5. Find the lead by phone number
6. Check all feedback fields

**Query**:
```sql
db.leads.findOne({ phone: "9876543210" })
```

**Expected Result**:
```json
{
  "_id": "69c763f59767fbce256df30d",
  "name": "John Doe",
  "phone": "9876543210",
  "store": "suitor guy-edappally",
  "leadType": "enquiry",
  "remarks": "Customer interested",
  "functionDate": "2026-04-10T00:00:00Z",
  "callDuration": 45,
  "subCategory": "Product Enquiry",
  "itemCategory": "Suit",
  "markAsComplaint": false,
  "callStatus": "Connected",
  "numberOfFunctions": "2",
  "numberOfAttires": "5",
  "competitor": "XYZ Store",
  "service": "Excellent",
  "refundStatus": "Security Amount Refunded",
  "createdAt": "2026-03-30T10:30:00Z",
  "updatedAt": "2026-03-30T10:35:00Z",
  "updatedBy": "Emp188"
}
```

**What to Check**:
- ✅ All feedback fields should be populated
- ✅ No fields should be null (except optional ones)
- ✅ Data should match what was submitted

---

## Comprehensive Test (30 minutes)

### Test 3: Outgoing Call Feedback Flow

**Scenario**: User makes outgoing call and submits feedback

**Steps**:
1. Open app
2. Go to Home screen
3. Click "Add Lead" or similar
4. Select "Outgoing Call"
5. Enter phone number: `9876543210`
6. Enter name: `Test Customer`
7. Click "Call Now"
8. Wait for call to complete
9. Fill feedback form:
   - Call Status: `Connected`
   - Remarks: `Customer interested in product`
   - Call Duration: Should auto-populate
   - Mark as Complaint: `No`
   - Sub Category: `Product Enquiry`
   - Item Category: `Suit`
   - Function Date: `2026-04-10`
10. Click "Save Lead"
11. Verify success message

**Verification**:
1. Open DevTools Network tab
2. Look for POST request to `/api/return/update/{id}`
3. Verify request body has all fields
4. Check database for the lead
5. Verify all feedback fields are saved

**Expected Result**:
- ✅ Lead created successfully
- ✅ Feedback saved to backend
- ✅ All fields present in database
- ✅ No data loss

---

### Test 4: Return Lead Feedback Update

**Scenario**: User updates return lead with feedback

**Steps**:
1. Open app
2. Go to Lead Screen
3. Select "Feedback Calls" tab
4. Click on a return lead
5. Click "Call Now"
6. Wait for call to complete
7. Fill feedback form:
   - Service: `Excellent`
   - Call Status: `Connected`
   - Remarks: `Good feedback`
   - Rating: `5`
   - Number of Functions: `2`
   - Number of Attires: `5`
   - Competitor: `XYZ Store`
   - Security Refund Status: `Security Amount Refunded`
8. Click "Save"
9. Verify success message

**Verification**:
1. Open DevTools Network tab
2. Look for PUT request to `/api/return/update/{id}`
3. Verify request body has all fields
4. Check database for the lead
5. Verify all feedback fields are updated

**Expected Result**:
- ✅ Feedback updated successfully
- ✅ All fields sent to backend
- ✅ All fields saved in database
- ✅ No data loss

---

## Error Scenarios

### Test 5: Network Error Handling

**Scenario**: Network fails during feedback update

**Steps**:
1. Open DevTools
2. Go to Network tab
3. Throttle network (Slow 3G)
4. Make outgoing call with feedback
5. Click "Save Lead"
6. Observe behavior

**Expected Result**:
- ✅ Lead is created
- ✅ Feedback update is attempted
- ✅ If update fails, warning is logged
- ✅ App continues (doesn't crash)
- ✅ User sees appropriate message

---

### Test 6: Missing Fields Handling

**Scenario**: User doesn't fill all optional fields

**Steps**:
1. Make outgoing call
2. Fill only required fields:
   - Call Status: `Connected`
   - Remarks: (empty)
3. Leave optional fields empty
4. Click "Save Lead"

**Expected Result**:
- ✅ Lead created successfully
- ✅ Only filled fields sent to backend
- ✅ Optional fields are null in database
- ✅ No errors

---

## Regression Tests

### Test 7: Existing Functionality Still Works

**Steps**:
1. Test creating new leads (non-outgoing call)
2. Test updating existing leads
3. Test follow-up leads
4. Test complaint leads
5. Test booking confirmation leads

**Expected Result**:
- ✅ All existing functionality works
- ✅ No breaking changes
- ✅ No new errors

---

## Performance Tests

### Test 8: API Response Time

**Steps**:
1. Make outgoing call with feedback
2. Open DevTools Network tab
3. Click "Save Lead"
4. Check response time for:
   - POST /api/lead/create
   - PUT /api/return/update/{id}

**Expected Result**:
- ✅ Create lead: < 2 seconds
- ✅ Update feedback: < 2 seconds
- ✅ Total time: < 4 seconds

---

## Data Integrity Tests

### Test 9: Verify No Duplicate Data

**Steps**:
1. Make outgoing call with feedback
2. Check database for duplicates
3. Query by phone number
4. Verify only one lead exists

**Query**:
```sql
db.leads.find({ phone: "9876543210" }).count()
```

**Expected Result**:
- ✅ Count should be 1
- ✅ No duplicates
- ✅ Data is consistent

---

### Test 10: Verify Data Consistency

**Steps**:
1. Make outgoing call with specific feedback
2. Check database
3. Verify all fields match what was submitted
4. Check timestamps are correct

**Expected Result**:
- ✅ All fields match
- ✅ Timestamps are correct
- ✅ Data is consistent

---

## Automated Testing

### Unit Tests

```dart
test('updateReturnLead includes all feedback fields', () async {
  final apiService = ApiService();
  
  final response = await apiService.updateReturnLead(
    id: 'test-id',
    callStatus: 'Connected',
    remarks: 'Test remarks',
    subCategory: 'Product Enquiry',
    itemCategory: 'Suit',
    functionDate: DateTime.now(),
    leadType: 'enquiry',
    markAsComplaint: false,
    numberOfFunctions: '2',
    numberOfAttires: '5',
    competitor: 'XYZ Store',
    service: 'Excellent',
    refundStatus: 'Security Amount Refunded',
  );
  
  expect(response['success'], true);
});
```

### Integration Tests

```dart
test('Outgoing call feedback is saved to backend', () async {
  // Create lead
  final leadResponse = await apiService.createLead(...);
  final leadId = leadResponse['lead']['_id'];
  
  // Update with feedback
  final updateResponse = await apiService.updateReturnLead(
    id: leadId,
    callStatus: 'Connected',
    remarks: 'Test feedback',
    // ... other fields
  );
  
  expect(updateResponse['success'], true);
  
  // Verify in database
  final lead = await database.leads.findOne({ _id: leadId });
  expect(lead['remarks'], 'Test feedback');
  expect(lead['callStatus'], 'Connected');
});
```

---

## Checklist for QA

- [ ] Test outgoing call feedback
- [ ] Test return lead feedback
- [ ] Test network error handling
- [ ] Test missing fields
- [ ] Test existing functionality
- [ ] Test API response times
- [ ] Test data integrity
- [ ] Test no duplicates
- [ ] Test data consistency
- [ ] Run automated tests
- [ ] Verify database
- [ ] Check logs
- [ ] Verify user experience
- [ ] Collect feedback

---

## Sign-Off

**Tested By**: _______________
**Date**: _______________
**Status**: _______________

- [ ] All tests passed
- [ ] No regressions found
- [ ] Ready for production

---

## Notes

- Keep DevTools open during testing
- Check browser console for errors
- Monitor API logs
- Verify database after each test
- Document any issues found
- Report bugs immediately
