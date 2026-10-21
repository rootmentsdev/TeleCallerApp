# Bugfix Requirements Document

## Introduction

JustDial leads are successfully fetched from the backend API and appear momentarily on the lead screen showing "0 Calls" in the JustDial section. However, they immediately disappear and the UI shows "No leads found". The root cause is that multiple sequential API calls (JustDial, Completed, and Return leads) all update the same shared lead list in the repository, with each API response overwriting the previous one. This causes JustDial leads to be removed when subsequent API calls execute.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN JustDial leads are fetched from the API and added to the repository THEN the leads appear briefly in the UI showing "0 Calls" in the JustDial section

1.2 WHEN Completed leads API response is fetched after JustDial leads THEN the Completed leads API call removes all existing JustDial leads from the repository by calling `_leads.removeWhere()` before adding new leads

1.3 WHEN Return leads API response is fetched after Completed leads THEN the Return leads API call removes all existing JustDial leads from the repository by calling `_leads.removeWhere()` before adding new leads

1.4 WHEN the lead screen displays leads after multiple API calls have executed THEN the UI shows "No leads found" because the final API call has removed all previously fetched leads

### Expected Behavior (Correct)

2.1 WHEN JustDial leads are fetched from the API and added to the repository THEN the leads are stored in the repository and persist in the UI

2.2 WHEN Completed leads API response is fetched after JustDial leads THEN the Completed leads are added to the repository WITHOUT removing JustDial leads that were previously fetched

2.3 WHEN Return leads API response is fetched after Completed leads THEN the Return leads are added to the repository WITHOUT removing JustDial leads or Completed leads that were previously fetched

2.4 WHEN the lead screen displays leads after multiple API calls have executed THEN the UI displays all lead types (JustDial, Completed, Return) that were fetched, filtered by the currently selected tab

### Unchanged Behavior (Regression Prevention)

3.1 WHEN a user manually refreshes a specific lead type tab (e.g., clicks on JustDial tab) THEN only that lead type should be refreshed from the API and duplicate leads of that type should be removed

3.2 WHEN a user switches between lead type tabs (JustDial, Completed, Return) THEN the UI should display only the leads of the selected category without affecting other categories in the repository

3.3 WHEN a lead has a follow-up date set THEN the lead should NOT be removed from the repository even when its category is being refreshed from the API

3.4 WHEN the app initializes and fetches all lead types sequentially THEN each lead type should be added to the repository independently without interfering with other lead types
