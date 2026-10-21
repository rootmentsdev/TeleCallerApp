# Feedback Calls Request Logging - Complete Flow

## Overview
Added comprehensive logging at every step of the feedback calls (return leads) request flow. This helps debug and verify that date parameters are being passed correctly through the entire chain.

---

## Logging Flow

### Step 1: LeadScreen View
**File:** `frontend/lib/view/lead_screen/lead_screen.dart`

When user taps "Feedback Calls" tab:

```
═══════════════════════════════════════════════════════════
LeadScreen: FETCHING FEEDBACK CALLS
═══════════════════════════════════════════════════════════
Store: SG-Edappally
Date From: 2026-03-15
Date To: 2026-03-15
Date Range Mode: false
Selected Date: 2026-03-15 00:00:00.000
═══════════════════════════════════════════════════════════
```

**What it shows:**
- Store filter being used
- Date range parameters
- Whether range mode is enabled
- Selected date from header controller

---

### Step 2: LeadScreenController
**File:** `frontend/lib/controller/lead_screen_controller.dart`

When controller receives the call:

```
═══════════════════════════════════════════════════════════
LeadScreenController: CALLING fetchReturnLeadsFromApi
═══════════════════════════════════════════════════════════
Parameters:
  store: SG-Edappally
  fromDate: 2026-03-15
  toDate: 2026-03-15
  enquiryFrom: null
  enquiryTo: null
═══════════════════════════════════════════════════════════
```

**What it shows:**
- All parameters being passed to repository
- Confirms date parameters are present
- Shows null values for optional parameters

---

### Step 3: LeadRepository
**File:** `frontend/lib/controller/lead_repository.dart`

When repository fetches from API:

```
═══════════════════════════════════════════════════════════
LeadRepository: FETCHING FEEDBACK CALLS (RETURN LEADS)
═══════════════════════════════════════════════════════════
Parameters:
  store: SG-Edappally
  fromDate: 2026-03-15
  toDate: 2026-03-15
  enquiryFrom: null
  enquiryTo: null
═══════════════════════════════════════════════════════════
```

**What it shows:**
- Parameters received by repository
- Confirms store and date filters
- Shows what will be sent to API

---

### Step 4: ApiService (Request)
**File:** `frontend/lib/services/api_service.dart`

When API service makes the request:

```
═══════════════════════════════════════════════════════════
ApiService: FEEDBACK CALLS (RETURN LEADS) REQUEST
═══════════════════════════════════════════════════════════
URL: https://rootstele.onrender.com/api/leads/returns?store=SG-Edappally&fromDate=2026-03-15&toDate=2026-03-15
Method: GET
Headers:
  Content-Type: application/json
  Accept: application/json
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Query Parameters:
  store: SG-Edappally
  fromDate: 2026-03-15
  toDate: 2026-03-15
  page: null
  limit: null
═══════════════════════════════════════════════════════════
```

**What it shows:**
- Complete URL with all query parameters
- HTTP method (GET)
- Request headers (with token truncated for security)
- All query parameters being sent

---

### Step 5: ApiService (Response)
**File:** `frontend/lib/services/api_service.dart`

When API responds:

```
═══════════════════════════════════════════════════════════
ApiService: FEEDBACK CALLS RESPONSE
═══════════════════════════════════════════════════════════
Status Code: 200
Response Headers:
  content-type: application/json
  content-length: 5432
  server: nginx
Response Body (First 500 chars):
{"success":true,"message":"Success","data":{"leads":[{"_id":"69b6832c05c2cb405e02669c","bookingNo":"202603040030007","leadtype":"return","__v":0,"bookingDate":"2026-03-04T13:37:32.000Z","category":"NON PREMIUM","createdAt":"2026-03-15T10:00:09.617Z","customerName":"RAHUL","deliveryDate":"2026-03-12T00:00:00.000Z","expectedReturnDate":"2026-03-15T00:00:00","itemCode":"3PP0924T32GLAYF5","itemName":"3PCS SUIT","leadStatus":"new","markasComplaint":false,"markasFollowup":false,"measurement":"0","normalizedPhone":"9207585588","phone":"9207585588","remarks":"W 29\nT 22.5\nK 17\nPL 37\nB 14\nHL 1.5","rentOutDate":"2026-03-12T00:00:00","returnAttendedBy":"AKSHAY","returnDate":"2026-03-15T09:57:34.000Z","source":"returnSync","store":"SG-Edappally","subCategory":"3PCS SUIT","trialDate":"2026-03-04T00:00:00","updatedAt":"2026-03-15T10:00:09.617Z","name":"RAHUL"}...
═══════════════════════════════════════════════════════════
```

**What it shows:**
- HTTP status code (200 = success)
- Response headers
- First 500 characters of response body
- Confirms data structure

---

## Complete Log Output Example

When user selects date 15/3/2026 and taps "Feedback Calls":

```
═══════════════════════════════════════════════════════════
LeadScreen: FETCHING FEEDBACK CALLS
═══════════════════════════════════════════════════════════
Store: SG-Edappally
Date From: 2026-03-15
Date To: 2026-03-15
Date Range Mode: false
Selected Date: 2026-03-15 00:00:00.000
═══════════════════════════════════════════════════════════

═══════════════════════════════════════════════════════════
LeadScreenController: CALLING fetchReturnLeadsFromApi
═══════════════════════════════════════════════════════════
Parameters:
  store: SG-Edappally
  fromDate: 2026-03-15
  toDate: 2026-03-15
  enquiryFrom: null
  enquiryTo: null
═══════════════════════════════════════════════════════════

═══════════════════════════════════════════════════════════
LeadRepository: FETCHING FEEDBACK CALLS (RETURN LEADS)
═══════════════════════════════════════════════════════════
Parameters:
  store: SG-Edappally
  fromDate: 2026-03-15
  toDate: 2026-03-15
  enquiryFrom: null
  enquiryTo: null
═══════════════════════════════════════════════════════════

═══════════════════════════════════════════════════════════
ApiService: FEEDBACK CALLS (RETURN LEADS) REQUEST
═══════════════════════════════════════════════════════════
URL: https://rootstele.onrender.com/api/leads/returns?store=SG-Edappally&fromDate=2026-03-15&toDate=2026-03-15
Method: GET
Headers:
  Content-Type: application/json
  Accept: application/json
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Query Parameters:
  store: SG-Edappally
  fromDate: 2026-03-15
  toDate: 2026-03-15
  page: null
  limit: null
═══════════════════════════════════════════════════════════

═══════════════════════════════════════════════════════════
ApiService: FEEDBACK CALLS RESPONSE
═══════════════════════════════════════════════════════════
Status Code: 200
Response Headers:
  content-type: application/json
  content-length: 5432
  server: nginx
Response Body (First 500 chars):
{"success":true,"message":"Success","data":{"leads":[{"_id":"69b6832c05c2cb405e02669c",...
═══════════════════════════════════════════════════════════

LeadRepository: Fetched 7 Return leads successfully, 0 failed
LeadRepository: Total leads in repository after fetch: 19
LeadRepository: Return leads in repository: 7
```

---

## What to Look For

### ✅ Correct Flow (Date Filtering Working)
```
URL: https://rootstele.onrender.com/api/leads/returns?store=SG-Edappally&fromDate=2026-03-15&toDate=2026-03-15
Status Code: 200
Fetched 7 Return leads successfully
```

### ❌ Incorrect Flow (No Date Filtering)
```
URL: https://rootstele.onrender.com/api/leads/returns?store=SG-Edappally
Status Code: 200
Fetched 100 Return leads successfully  ← TOO MANY!
```

---

## Debugging Tips

### 1. Check if Date Parameters Are Present
Look for `fromDate` and `toDate` in the URL:
```
✅ GOOD: ?store=SG-Edappally&fromDate=2026-03-15&toDate=2026-03-15
❌ BAD:  ?store=SG-Edappally
```

### 2. Verify Date Format
Dates should be in `YYYY-MM-DD` format:
```
✅ GOOD: 2026-03-15
❌ BAD:  15/3/2026 or 2026-3-15
```

### 3. Check Response Count
Should match backend filtering:
```
✅ GOOD: Fetched 7 Return leads successfully
❌ BAD:  Fetched 100 Return leads successfully
```

### 4. Verify Store Filter
Store should be included if selected:
```
✅ GOOD: store: SG-Edappally
✅ GOOD: store: null (if "All Stores" selected)
```

---

## Files Modified

1. **frontend/lib/view/lead_screen/lead_screen.dart**
   - Added logging in `_fetchReturnLeads()` method
   - Shows store, dates, and date range mode

2. **frontend/lib/controller/lead_screen_controller.dart**
   - Added logging in `fetchReturnLeadsFromApi()` method
   - Shows all parameters being passed

3. **frontend/lib/controller/lead_repository.dart**
   - Added logging in `fetchReturnLeadsFromApi()` method
   - Shows parameters received from controller

4. **frontend/lib/services/api_service.dart**
   - Added detailed request logging (URL, headers, query params)
   - Added detailed response logging (status, headers, body preview)

---

## Summary

The logging provides complete visibility into the feedback calls request flow:

1. **View Layer** - Shows what the UI is sending
2. **Controller Layer** - Shows what the controller is passing
3. **Repository Layer** - Shows what the repository is sending to API
4. **API Layer** - Shows the complete HTTP request and response

This makes it easy to identify where date parameters are being lost or not passed correctly.
