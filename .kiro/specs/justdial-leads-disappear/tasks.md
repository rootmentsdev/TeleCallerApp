# Implementation Tasks - JustDial Leads Disappearing Bugfix

## Overview

This task list implements the bugfix for JustDial leads disappearing after sequential API calls. The workflow follows the exploratory bugfix methodology: first write tests to surface the bug, then implement the fix, then verify the fix works and preserves existing behavior.

---

## Phase 1: Exploration - Understand the Bug

- [ ] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Sequential API Calls Remove Leads from Other Categories
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For deterministic bugs, scope the property to the concrete failing case(s) to ensure reproducibility
  - Test implementation details from Bug Condition in design:
    - Simulate sequential API calls: fetchJustDialLeadsFromApi() → fetchReturnLeadsFromApi() → fetchBookingConfirmationLeadsFromApi()
    - Verify that leads from all three categories are present in the repository after all calls complete
    - Assert that JustDial leads are NOT removed when Return leads are fetched
    - Assert that Return leads are NOT removed when Booking Confirmation leads are fetched
    - Assert that all leads from all categories remain in the repository
  - The test assertions should match the Expected Behavior Properties from design
  - Run test on UNFIXED code
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found to understand root cause (e.g., "After fetching all three categories, only Booking Confirmation leads remain")
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Non-Buggy Inputs Preserve Existing Behavior
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED code for non-buggy inputs (single category fetches, individual lead operations)
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements:
    - Single category fetch (JustDial only) should work correctly without affecting other categories
    - Individual lead updates (call status, follow-up date changes) should work correctly
    - Lead deletion operations should work correctly
    - Leads with follow-up dates should persist across refreshes
    - Manual refresh of a specific lead type only removes duplicates of that type
    - UI displays all lead types appropriately based on the selected tab
    - Switching between lead type tabs displays only the leads of the selected category without affecting other categories in the repository
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED code
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed code
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

---

## Phase 2: Implementation - Apply the Fix

- [ ] 3. Fix for JustDial leads disappearing due to sequential API calls

  - [ ] 3.1 Implement atomic operations in fetchJustDialLeadsFromApi()
    - Collect all leads to remove first (category == JustDial AND !needsFollowUp)
    - Collect all leads to add first (parse API response)
    - Perform removal and addition in a single atomic operation
    - Call notifyListeners() once after all changes
    - Add detailed logging to track which leads are being removed and added
    - Verify that leads from other categories (Return, Booking Confirmation) are NOT affected
    - _Bug_Condition: isBugCondition(input) where multiple sequential API calls update shared _leads list_
    - _Expected_Behavior: Each lead type managed independently; fetching one category does not remove leads from other categories_
    - _Preservation: Leads with follow-up dates must persist across refreshes_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

  - [ ] 3.2 Implement atomic operations in fetchReturnLeadsFromApi()
    - Collect all leads to remove first (category == Return AND !needsFollowUp)
    - Collect all leads to add first (parse API response)
    - Perform removal and addition in a single atomic operation
    - Call notifyListeners() once after all changes
    - Add detailed logging to track which leads are being removed and added
    - Verify that leads from other categories (JustDial, Booking Confirmation) are NOT affected
    - _Bug_Condition: isBugCondition(input) where multiple sequential API calls update shared _leads list_
    - _Expected_Behavior: Each lead type managed independently; fetching one category does not remove leads from other categories_
    - _Preservation: Leads with follow-up dates must persist across refreshes_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

  - [ ] 3.3 Implement atomic operations in fetchBookingConfirmationLeadsFromApi()
    - Collect all leads to remove first (category == Booking Confirmation AND !needsFollowUp)
    - Collect all leads to add first (parse API response)
    - Perform removal and addition in a single atomic operation
    - Call notifyListeners() once after all changes
    - Add detailed logging to track which leads are being removed and added
    - Verify that leads from other categories (JustDial, Return) are NOT affected
    - _Bug_Condition: isBugCondition(input) where multiple sequential API calls update shared _leads list_
    - _Expected_Behavior: Each lead type managed independently; fetching one category does not remove leads from other categories_
    - _Preservation: Leads with follow-up dates must persist across refreshes_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4_

  - [ ] 3.4 Add comprehensive logging for debugging
    - Log the number of leads before and after each fetch operation
    - Log the number of leads removed and added for each category
    - Log the number of leads preserved (with follow-up dates)
    - Log the total leads in repository after each operation
    - Log the breakdown of leads by category after each operation
    - Use consistent logging format for easy parsing and debugging
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

---

## Phase 3: Validation - Verify the Fix

- [ ] 4. Verify bug condition exploration test now passes
  - **Property 1: Expected Behavior** - Sequential API Calls Maintain All Leads
  - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
  - The test from task 1 encodes the expected behavior
  - When this test passes, it confirms the expected behavior is satisfied
  - Run bug condition exploration test from step 1
  - **EXPECTED OUTCOME**: Test PASSES (confirms bug is fixed)
  - Verify that sequential API calls now maintain all leads from all categories
  - Verify that leads from other categories are NOT removed when one category is fetched
  - Verify that leads with follow-up dates are preserved across all refresh operations
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 5. Verify preservation tests still pass
  - **Property 2: Preservation** - Non-Buggy Inputs Still Work Correctly
  - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
  - Run preservation property tests from step 2
  - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions)
  - Confirm all tests still pass after fix (no regressions)
  - Verify that single category fetches work correctly
  - Verify that individual lead operations work correctly
  - Verify that leads with follow-up dates persist across refreshes
  - Verify that tab switching displays correct leads without affecting repository state
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

---

## Phase 4: Checkpoint

- [ ] 6. Checkpoint - Ensure all tests pass and fix is complete
  - Verify that all exploration tests pass (bug is fixed)
  - Verify that all preservation tests pass (no regressions)
  - Verify that sequential API calls work correctly (JustDial → Return → Booking Confirmation)
  - Verify that leads from all categories are present in repository after all calls
  - Verify that leads with follow-up dates are preserved across all refresh operations
  - Verify that logging shows correct counts and breakdown by category
  - Verify that UI displays all lead types correctly based on selected tab
  - Verify that manual refresh of a specific lead type only removes duplicates of that type
  - Ensure all tests pass, ask the user if questions arise.
