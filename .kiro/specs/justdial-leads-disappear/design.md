# JustDial Leads Disappearing Bugfix Design

## Overview

JustDial leads are successfully fetched from the backend API and appear momentarily in the UI showing "0 Calls" in the JustDial section. However, they immediately disappear and the UI shows "No leads found". The root cause is that multiple sequential API calls (JustDial, Completed, and Return leads) all update the same shared lead list in the repository. Each fetch method calls `_leads.removeWhere()` to remove existing leads of that category before adding new ones, causing previously fetched leads from other categories to be removed.

The fix ensures that each lead type is managed independently without interfering with others, while preserving leads with follow-up dates and maintaining proper filtering logic for different lead types.

## Glossary

- **Bug_Condition (C)**: Multiple sequential API calls (JustDial, Completed, Return) all update the same shared `_leads` list, with each call removing all leads of its category before adding new ones, causing previously fetched leads to be removed
- **Property (P)**: Each lead type should be managed independently; fetching one category should not remove leads from other categories
- **Preservation**: Leads with follow-up dates must persist across refreshes; manual refresh of a specific lead type only removes duplicates of that type; UI displays all lead types appropriately based on selected tab
- **LeadRepository**: The singleton repository in `frontend/lib/controller/lead_repository.dart` that manages all lead data in the `_leads` list
- **Lead Category**: The classification of a lead (JustDial, Completed/Return, Booking Confirmation, Follow-Up, etc.)
- **removeWhere()**: The method that removes leads from the `_leads` list based on a condition, currently causing the bug

## Bug Details

### Bug Condition

The bug manifests when the app initializes and sequentially fetches leads from multiple API endpoints. The `fetchJustDialLeadsFromApi()`, `fetchReturnLeadsFromApi()`, and `fetchBookingConfirmationLeadsFromApi()` methods all operate on the same shared `_leads` list. Each method calls `_leads.removeWhere()` to remove existing leads of that category before adding new ones. When these calls execute sequentially, the removal logic removes leads from other categories that were just fetched, causing data loss.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type SequentialApiCalls
  OUTPUT: boolean
  
  RETURN input.callSequence IN [JustDial, Completed, Return]
         AND input.sharedLeadsList == _leads
         AND EACH call invokes removeWhere() on _leads
         AND removeWhere() removes leads by category
         AND leads from previous calls are removed by subsequent calls
END FUNCTION
```

### Examples

**Example 1: JustDial leads disappear after Completed leads fetch**
- Step 1: `fetchJustDialLeadsFromApi()` is called
  - Removes all existing JustDial leads: `_leads.removeWhere((lead) => lead.category == 'Just Dial' && !lead.needsFollowUp)`
  - Adds 3 new JustDial leads to `_leads`
  - Repository now contains: [JustDial-1, JustDial-2, JustDial-3]
  - UI displays: "3 JustDial leads"
- Step 2: `fetchReturnLeadsFromApi()` is called
  - Removes all existing Return leads: `_leads.removeWhere((lead) => lead.category == 'Return' && !lead.needsFollowUp)`
  - Adds 2 new Return leads to `_leads`
  - Repository now contains: [JustDial-1, JustDial-2, JustDial-3, Return-1, Return-2]
  - UI displays: "3 JustDial + 2 Return leads"
- Step 3: `fetchBookingConfirmationLeadsFromApi()` is called
  - Removes all existing Booking Confirmation leads: `_leads.removeWhere((lead) => lead.category == 'Booking Confirmation' && !lead.needsFollowUp)`
  - Adds 1 new Booking Confirmation lead to `_leads`
  - Repository now contains: [JustDial-1, JustDial-2, JustDial-3, Return-1, Return-2, BookingConf-1]
  - UI displays: "3 JustDial + 2 Return + 1 Booking Confirmation leads"
- **Expected**: All leads remain visible
- **Actual**: Leads disappear due to race conditions or improper filtering

**Example 2: Follow-up leads are incorrectly removed**
- A lead with `followUpDate` set is fetched and stored
- When the same category is refreshed, the lead should be preserved because `needsFollowUp == true`
- **Expected**: Lead persists in repository
- **Actual**: Lead may be removed if filtering logic is incorrect

**Example 3: Manual refresh of JustDial tab removes other categories**
- User is viewing all leads (JustDial, Return, Booking Confirmation)
- User clicks on JustDial tab to refresh only JustDial leads
- `fetchJustDialLeadsFromApi()` is called
- **Expected**: Only JustDial leads are refreshed; Return and Booking Confirmation leads remain unchanged
- **Actual**: Other categories may be affected due to shared list management

**Edge Case: Empty API response**
- API returns empty list for a category
- `removeWhere()` removes all existing leads of that category
- **Expected**: Category shows "No leads found"
- **Actual**: Behavior is correct, but should not affect other categories

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Mouse clicks on action buttons must continue to work exactly as before
- Button display with numbered shortcuts must remain unchanged
- Game state transitions between UI contexts must remain unchanged
- Leads with follow-up dates must persist across refreshes
- Manual refresh of a specific lead type only removes duplicates of that type
- UI displays all lead types appropriately based on the selected tab
- Switching between lead type tabs displays only the leads of the selected category without affecting other categories in the repository

**Scope:**
All inputs that do NOT involve sequential API calls updating the same shared lead list should be completely unaffected by this fix. This includes:
- Individual lead updates (call status, follow-up date changes)
- Lead deletion operations
- Lead creation operations
- UI filtering and display logic
- Tab switching behavior

## Hypothesized Root Cause

Based on the bug description, the most likely issues are:

1. **Shared Lead List Management**: All three API fetch methods (`fetchJustDialLeadsFromApi()`, `fetchReturnLeadsFromApi()`, `fetchBookingConfirmationLeadsFromApi()`) operate on the same `_leads` list. Each method removes leads by category before adding new ones, but this removal logic doesn't account for leads from other categories that may have been fetched in parallel or sequentially.

2. **Improper Category-Based Removal**: The `removeWhere()` calls are designed to remove only leads of a specific category, but the logic may not properly distinguish between categories or may have race conditions when multiple API calls execute in quick succession.

3. **Race Condition in Sequential Calls**: When `initState()` calls all three fetch methods in sequence with a 500ms delay, the removal logic in one method may interfere with leads added by another method if the timing is off.

4. **Follow-Up Date Preservation Logic**: The condition `!lead.needsFollowUp` is meant to preserve leads with follow-up dates, but this logic may not be consistently applied across all fetch methods or may have edge cases where it fails.

5. **Lack of Atomic Operations**: The removal and addition of leads are not atomic operations. Between the `removeWhere()` call and the addition of new leads, the repository state is inconsistent, which could cause UI rendering issues or data loss if another operation accesses the list during this window.

## Correctness Properties

Property 1: Bug Condition - Independent Lead Category Management

_For any_ sequential API calls where multiple lead categories (JustDial, Return, Booking Confirmation) are fetched, the fixed repository SHALL maintain all leads from all categories in the `_leads` list without removing leads from other categories. Each category's fetch operation SHALL only remove duplicate leads of that specific category (those without follow-up dates) before adding new leads.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4**

Property 2: Preservation - Follow-Up Date Persistence and Tab Filtering

_For any_ lead that has a follow-up date set, the fixed repository SHALL preserve that lead across all refresh operations, regardless of which category is being refreshed. Additionally, when a user switches between lead type tabs or manually refreshes a specific category, the fixed repository SHALL display only the leads of the selected category without affecting other categories in the repository.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

**File**: `frontend/lib/controller/lead_repository.dart`

**Functions Affected**:
1. `fetchJustDialLeadsFromApi()`
2. `fetchReturnLeadsFromApi()`
3. `fetchBookingConfirmationLeadsFromApi()`

**Specific Changes**:

1. **Ensure Category-Specific Removal**: Each fetch method should only remove leads of its own category, not affecting other categories. The current logic already does this with the category check, but we need to verify it's working correctly.

2. **Preserve Follow-Up Leads**: All fetch methods should preserve leads that have `followUpDate` set (i.e., `lead.needsFollowUp == true`). This is already implemented with the `!lead.needsFollowUp` condition, but we need to ensure it's consistently applied.

3. **Add Atomic Operations**: Wrap the removal and addition operations in a way that prevents race conditions. This can be done by:
   - Collecting all leads to remove first
   - Collecting all leads to add first
   - Then performing the removal and addition in a single operation
   - Finally calling `notifyListeners()` once

4. **Improve Logging**: Add detailed logging to track which leads are being removed and added, making it easier to debug future issues.

5. **Verify API Response Parsing**: Ensure that the API response is being parsed correctly and that leads are being created with the correct category.

### Implementation Details

**For `fetchJustDialLeadsFromApi()`**:
```dart
// Current problematic code:
_leads.removeWhere(
  (lead) =>
      lead.category == LeadConstants.categoryJustDial &&
      !lead.needsFollowUp,
);

// Fixed code (same logic, but with better atomicity):
// 1. Collect leads to remove
final leadsToRemove = _leads.where(
  (lead) =>
      lead.category == LeadConstants.categoryJustDial &&
      !lead.needsFollowUp,
).toList();

// 2. Remove collected leads
for (final lead in leadsToRemove) {
  _leads.remove(lead);
}

// 3. Add new leads
for (var leadData in leadsData) {
  // ... parse and add lead
}

// 4. Notify listeners once
notifyListeners();
```

**For `fetchReturnLeadsFromApi()`**:
- Apply the same atomic operation pattern
- Ensure only Return leads are removed
- Preserve leads with follow-up dates

**For `fetchBookingConfirmationLeadsFromApi()`**:
- Apply the same atomic operation pattern
- Ensure only Booking Confirmation leads are removed
- Preserve leads with follow-up dates

### Additional Improvements

1. **Add Validation**: After each fetch, validate that leads from other categories are still present in the repository.

2. **Add Counters**: Track how many leads were removed, added, and preserved for each category to help with debugging.

3. **Improve Error Handling**: If an error occurs during the fetch, ensure that the repository state is not left in an inconsistent state.

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Write tests that simulate sequential API calls for each lead category and assert that leads from all categories are present in the repository after all calls complete. Run these tests on the UNFIXED code to observe failures and understand the root cause.

**Test Cases**:
1. **Sequential JustDial + Return Fetch Test**: Simulate fetching JustDial leads, then Return leads, and verify both are present (will fail on unfixed code)
2. **Sequential JustDial + Return + Booking Confirmation Fetch Test**: Simulate fetching all three categories sequentially and verify all are present (will fail on unfixed code)
3. **Follow-Up Date Preservation Test**: Simulate fetching leads with follow-up dates and verify they persist across subsequent fetches (may fail on unfixed code)
4. **Tab Switching Test**: Simulate switching between tabs and verify only the selected category is displayed without affecting other categories (may fail on unfixed code)

**Expected Counterexamples**:
- After fetching JustDial leads and then Return leads, the JustDial leads are missing from the repository
- After fetching all three categories, only the last category's leads are present
- Leads with follow-up dates are removed when their category is refreshed
- Switching tabs causes leads from other categories to disappear

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds (sequential API calls), the fixed function produces the expected behavior (all leads from all categories are present).

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := fetchAllLeadsSequentially_fixed(input)
  ASSERT allLeadsFromAllCategoriesPresent(result)
  ASSERT leadsWithFollowUpDatesPreserved(result)
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold (single category fetch, individual lead operations), the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT originalFunction(input) = fixedFunction(input)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for single category fetches and individual lead operations, then write property-based tests capturing that behavior.

**Test Cases**:
1. **Single Category Fetch Preservation**: Verify that fetching only JustDial leads works correctly and doesn't affect other categories
2. **Individual Lead Update Preservation**: Verify that updating a single lead's call status or follow-up date works correctly
3. **Lead Deletion Preservation**: Verify that deleting a lead works correctly and doesn't affect other leads
4. **Tab Switching Preservation**: Verify that switching between tabs displays the correct leads without affecting the repository state

### Unit Tests

- Test sequential fetches of all three categories and verify all leads are present
- Test follow-up date preservation across refreshes
- Test that leads from other categories are not affected when one category is refreshed
- Test edge cases (empty API response, API error, malformed data)
- Test that leads with follow-up dates are preserved even when their category is refreshed

### Property-Based Tests

- Generate random sequences of API calls and verify all leads are present after each call
- Generate random lead configurations with follow-up dates and verify they persist across refreshes
- Generate random tab switches and verify the correct leads are displayed
- Test that all non-buggy inputs continue to work correctly across many scenarios

### Integration Tests

- Test full app initialization with sequential API calls for all three categories
- Test switching between lead type tabs and verifying the correct leads are displayed
- Test manual refresh of a specific lead type and verifying other categories are not affected
- Test that leads with follow-up dates persist across app restarts (via SharedPreferences)
