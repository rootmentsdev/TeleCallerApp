# Store Filter Issue - Quick Reference

## TL;DR

**Problem:** When filtering by "Dapper Squad - Edappally", the app shows leads from all brands at Edappally (SG, Z, DS) instead of just DS.

**Root Cause:** Backend is filtering only by location ("Edappally"), not by brand ("DS").

**Solution:** Backend needs to parse the store parameter and filter by BOTH brand AND location.

---

## What Frontend Sends to Backend

```
GET /api/leads?store=DS-Edappally
```

✅ **This is correct.** Frontend is doing its job.

---

## What Backend Should Do

```python
# Parse: "DS-Edappally" → brand="DS", location="Edappally"
# Query: WHERE brand='DS' AND location='Edappally'
# Return: Only DS-Edappally leads
```

---

## What Backend is Actually Doing

```python
# Query: WHERE location='Edappally'
# Return: SG-Edappally, Z-Edappally, DS-Edappally (ALL brands)
```

---

## How to Fix

### Backend Code Change

**Before (Wrong):**
```python
location = store_param.split('-')[1]  # Extracts only location
leads = db.leads.find({'location': location})
```

**After (Correct):**
```python
parts = store_param.split('-', 1)
brand = parts[0]
location = parts[1]
leads = db.leads.find({'brand': brand, 'location': location})
```

---

## Files to Check

### Frontend Files (All Correct ✅)
- `lib/controller/header_controller.dart` — Store selection
- `lib/controller/lead_repository.dart` — API calls
- `lib/services/api_service.dart` — HTTP requests
- `lib/utils/api_config.dart` — URL construction

### Backend Files (Needs Fix ❌)
- API endpoint: `/api/leads`
- Query logic: Should filter by brand AND location
- Response: Should return only matching leads

---

## Test the Fix

### Before Fix
```bash
curl "https://rootstele-imrn.onrender.com/api/leads?store=DS-Edappally"
# Returns: SG-Edappally, Z-Edappally, DS-Edappally ❌
```

### After Fix
```bash
curl "https://rootstele-imrn.onrender.com/api/leads?store=DS-Edappally"
# Returns: DS-Edappally only ✅
```

---

## Store Parameter Format

All store parameters follow this format:
```
{BRAND}-{LOCATION}
```

Examples:
- `SG-Edappally` (Suitor Guy - Edappally)
- `Z-Edappally` (Zorucci - Edappally)
- `DS-Edappally` (Dapper Squad - Edappally)
- `SG-Trivandrum` (Suitor Guy - Trivandrum)

---

## Key Points

1. **Frontend is correct** — It passes the full store parameter (brand-location)
2. **Backend is wrong** — It filters only by location, ignoring the brand
3. **Fix is simple** — Parse the store parameter and filter by both brand and location
4. **Impact** — Affects all store filtering across the app (Home, Lead, Report screens)

---

## Documentation Files Created

1. **STORE_FILTER_ISSUE_SUMMARY.md** — Executive summary with code evidence
2. **STORE_FILTER_FLOW_DIAGRAM.md** — Visual flow diagram of the issue
3. **STORE_FILTER_CODE_TRACE.md** — Step-by-step code execution trace
4. **STORE_FILTER_ANALYSIS.md** — Detailed technical analysis
5. **STORE_FILTER_QUICK_REFERENCE.md** — This file

---

## Next Steps

1. ✅ Frontend is ready (no changes needed)
2. ❌ Backend needs to be fixed
3. Test the fix with all store combinations
4. Verify filtering works on all screens
