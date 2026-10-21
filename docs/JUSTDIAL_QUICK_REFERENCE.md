# JustDial Lead Flow - Quick Reference

## API Endpoints Summary

| Operation | Method | Endpoint | Purpose |
|-----------|--------|----------|---------|
| List Leads | GET | `/api/leads/justdial` | Fetch all JustDial leads with filters |
| Get Details | GET | `/api/leads/justdial/{id}` | Get single JustDial lead details |
| Update Lead | PUT | `/api/leads/justdial/{id}` | Update JustDial lead status/remarks |

## Base URL
```
https://rootstele-imrn.onrender.com
```

## Quick Examples

### 1. Get Today's JustDial Leads
```dart
final leads = await apiService.getJustDialLeads(
  fromDate: '2026-05-02',
  toDate: '2026-05-02',
  limit: 100,
);
```

### 2. Get Lead Details
```dart
final lead = await apiService.getJustDialLeadById('justdial_001');
```

### 3. Update Lead Status
```dart
await apiService.updateJustDialLead(
  'justdial_001',
  {
    'leadStatus': 'contacted',
    'remarks': 'Called - interested in services',
    'callDuration': 120,
  },
);
```

## Lead Status Flow

```
new → contacted → interested/not_interested
                ↓
            follow_up → converted/lost
```

## Implementation Files

| File | Changes |
|------|---------|
| `frontend/lib/utils/api_config.dart` | Added `updateJustDialLead(id)` |
| `frontend/lib/services/api_service.dart` | Added `updateJustDialLead(id, data)` |

## Response Format

### Success (200)
```json
{
  "success": true,
  "data": { /* lead data */ }
}
```

### Error (4xx/5xx)
```json
{
  "success": false,
  "error": "Error message",
  "statusCode": 400
}
```

## Key Fields

- `_id`: Lead ID
- `name`: Lead name
- `phone`: Phone number
- `store`: Store location
- `leadStatus`: Current status
- `remarks`: Notes
- `callDuration`: Call duration (seconds)
- `followUpDate`: Next follow-up date
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

## Query Parameters

| Parameter | Type | Example |
|-----------|------|---------|
| `store` | String | "MG Road" |
| `fromDate` | String | "2026-05-01" |
| `toDate` | String | "2026-05-02" |
| `page` | Integer | 1 |
| `limit` | Integer | 100 |

## Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Bad request |
| 401 | Unauthorized |
| 404 | Not found |
| 500 | Server error |

## Common Workflows

### Workflow 1: Process New JustDial Lead
1. Fetch new leads: `getJustDialLeads()`
2. Get lead details: `getJustDialLeadById(id)`
3. Update status to "contacted": `updateJustDialLead(id, {leadStatus: 'contacted'})`

### Workflow 2: Follow-up on Lead
1. Get lead details: `getJustDialLeadById(id)`
2. Update with follow-up date: `updateJustDialLead(id, {followUpDate: '2026-05-05'})`

### Workflow 3: Convert Lead
1. Get lead details: `getJustDialLeadById(id)`
2. Update status to "converted": `updateJustDialLead(id, {leadStatus: 'converted'})`

## Error Handling

```dart
try {
  final lead = await apiService.getJustDialLeadById(id);
} on AuthenticationException {
  // Handle auth error
} catch (e) {
  // Handle other errors
  print('Error: $e');
}
```

## Notes

- All dates should be in `YYYY-MM-DD` format
- Phone numbers should include country code
- Call duration is in seconds
- Timestamps are in ISO 8601 format
- API requires Bearer token authentication
