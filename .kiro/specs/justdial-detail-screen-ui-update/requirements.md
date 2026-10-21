# Requirements Document: JustDial Detail Screen UI Update

## Introduction

The JustDial detail screen currently displays basic call information with minimal form fields for call status and remarks. This feature updates the UI to match a new design mockup that provides a comprehensive form layout for capturing detailed call information, including customer details, location information, function dates, complaint tracking, categorization, and follow-up scheduling. The updated design improves data collection and user experience by organizing fields logically with proper visual hierarchy, icons, and validation indicators.

## Glossary

- **JustDial_Detail_Screen**: The Flutter screen widget that displays and manages JustDial lead information and call details
- **Phone_Number_Field**: Input field for displaying and validating customer phone numbers with associated icon
- **Customer_Name_Field**: Optional text input field for customer name with associated icon
- **Store_Dropdown**: Dropdown selector for choosing the store/brand location
- **Location_Dropdown**: Dropdown selector for choosing the geographic location
- **Function_Date_Field**: Date picker field for selecting the function/event date
- **Call_Duration_Display**: Read-only display showing the duration of the completed call
- **Mark_as_Complaint_Checkbox**: Boolean toggle to indicate if the call should be marked as a complaint
- **Sub_Category_Dropdown**: Dropdown selector for choosing the sub-category with required field indicator
- **Close_Reason_Dropdown**: Dropdown selector for choosing the reason for closing with required field indicator
- **Item_Category_Dropdown**: Dropdown selector for choosing the item category with required field indicator
- **Call_Remarks_TextArea**: Multi-line text input for capturing detailed call notes and remarks
- **Mark_as_Follow_Up_Checkbox**: Boolean toggle to indicate if a follow-up is needed
- **Follow_Ups_Date_Field**: Date picker field for scheduling the follow-up date
- **Save_Lead_Button**: Action button to persist all entered data
- **Cancel_Button**: Action button to discard changes and return to previous screen
- **Required_Field_Badge**: Visual indicator (typically "R" badge) showing that a field is mandatory
- **Design_Mockup**: The reference UI design provided by the design team showing the new layout and visual hierarchy

## Requirements

### Requirement 1: Display Phone Number Field with Icon

**User Story:** As a telecaller, I want to see the customer's phone number prominently displayed at the top of the form with a phone icon, so that I can quickly reference the contact information.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL display the Phone_Number_Field at the top of the form
2. THE Phone_Number_Field SHALL include a phone icon to the left of the phone number
3. THE Phone_Number_Field SHALL display the phone number in a readable format (e.g., "+91 XXXXXXXXXX")
4. THE Phone_Number_Field SHALL be read-only and not editable by the user

---

### Requirement 2: Display Optional Customer Name Field with Icon

**User Story:** As a telecaller, I want to optionally enter or view the customer's name with a name icon, so that I can personalize the interaction and maintain customer records.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL display the Customer_Name_Field below the Phone_Number_Field
2. THE Customer_Name_Field SHALL include a name/person icon to the left of the input
3. THE Customer_Name_Field SHALL be optional and allow empty values
4. THE Customer_Name_Field SHALL accept text input up to a reasonable character limit (e.g., 100 characters)
5. THE Customer_Name_Field SHALL display a placeholder text indicating it is optional

---

### Requirement 3: Display Store and Location Dropdowns Side by Side

**User Story:** As a telecaller, I want to select the store and location in a side-by-side layout, so that I can efficiently specify where the customer is located without excessive scrolling.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL display the Store_Dropdown and Location_Dropdown on the same row
2. THE Store_Dropdown SHALL be positioned on the left side and occupy approximately 50% of the available width
3. THE Location_Dropdown SHALL be positioned on the right side and occupy approximately 50% of the available width
4. THE Store_Dropdown SHALL display a list of available stores/brands
5. THE Location_Dropdown SHALL display a list of available locations
6. BOTH dropdowns SHALL have a minimum spacing of 8 pixels between them

---

### Requirement 4: Display Function Date Field with Date Picker and Call Duration Display Side by Side

**User Story:** As a telecaller, I want to select the function date and view the call duration in a side-by-side layout, so that I can see both the event date and call metrics without scrolling.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL display the Function_Date_Field and Call_Duration_Display on the same row
2. THE Function_Date_Field SHALL be positioned on the left side and occupy approximately 50% of the available width
3. THE Call_Duration_Display SHALL be positioned on the right side and occupy approximately 50% of the available width
4. THE Function_Date_Field SHALL include a date picker that opens when tapped
5. THE Call_Duration_Display SHALL show the duration in a readable format (e.g., "2 minutes 30 seconds" or "2:30")
6. THE Call_Duration_Display SHALL be read-only and not editable
7. BOTH fields SHALL have a minimum spacing of 8 pixels between them

---

### Requirement 5: Display Mark as Complaint Checkbox

**User Story:** As a telecaller, I want to mark a call as a complaint with a checkbox, so that I can flag issues that need escalation or follow-up.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL display the Mark_as_Complaint_Checkbox below the Function_Date_Field
2. THE Mark_as_Complaint_Checkbox SHALL have a label "Mark as Complaint" next to the checkbox
3. THE Mark_as_Complaint_Checkbox SHALL be unchecked by default
4. WHEN the Mark_as_Complaint_Checkbox is toggled, THE JustDial_Detail_Screen SHALL update the checkbox state immediately

---

### Requirement 6: Display Sub Category Dropdown with Required Field Badge

**User Story:** As a telecaller, I want to select a sub-category from a dropdown with a clear indication that it is required, so that I can properly categorize the call and ensure data completeness.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL display the Sub_Category_Dropdown below the Mark_as_Complaint_Checkbox
2. THE Sub_Category_Dropdown SHALL display a Required_Field_Badge (e.g., "R" badge) next to the label
3. THE Sub_Category_Dropdown SHALL display a list of available sub-categories
4. THE Sub_Category_Dropdown SHALL have no default selection initially
5. WHEN the user attempts to save without selecting a sub-category, THE JustDial_Detail_Screen SHALL display a validation error

---

### Requirement 7: Display Close Reason Dropdown with Required Field Badge

**User Story:** As a telecaller, I want to select a close reason from a dropdown with a clear indication that it is required, so that I can document why the call was concluded.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL display the Close_Reason_Dropdown below the Sub_Category_Dropdown
2. THE Close_Reason_Dropdown SHALL display a Required_Field_Badge (e.g., "R" badge) next to the label
3. THE Close_Reason_Dropdown SHALL display a list of available close reasons
4. THE Close_Reason_Dropdown SHALL have no default selection initially
5. WHEN the user attempts to save without selecting a close reason, THE JustDial_Detail_Screen SHALL display a validation error

---

### Requirement 8: Display Item Category Dropdown with Required Field Badge and "Kurta" Indicator

**User Story:** As a telecaller, I want to select an item category from a dropdown with a clear indication that it is required and see the current category, so that I can properly categorize the product being discussed.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL display the Item_Category_Dropdown below the Close_Reason_Dropdown
2. THE Item_Category_Dropdown SHALL display a Required_Field_Badge (e.g., "R" badge) next to the label
3. THE Item_Category_Dropdown SHALL display a list of available item categories
4. THE Item_Category_Dropdown SHALL display "Kurta" as a visual indicator or default category reference
5. THE Item_Category_Dropdown SHALL have no default selection initially
6. WHEN the user attempts to save without selecting an item category, THE JustDial_Detail_Screen SHALL display a validation error

---

### Requirement 9: Display Call Remarks/Notes Text Area

**User Story:** As a telecaller, I want to enter detailed notes about the call in a text area, so that I can document important information and context for future reference.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL display the Call_Remarks_TextArea below the Item_Category_Dropdown
2. THE Call_Remarks_TextArea SHALL be a multi-line text input field
3. THE Call_Remarks_TextArea SHALL have a minimum height of 80 pixels to accommodate multiple lines
4. THE Call_Remarks_TextArea SHALL accept text input up to a reasonable character limit (e.g., 500 characters)
5. THE Call_Remarks_TextArea SHALL display a character count or limit indicator
6. THE Call_Remarks_TextArea SHALL be optional and allow empty values

---

### Requirement 10: Display Mark as Follow Up Checkbox

**User Story:** As a telecaller, I want to mark a call as requiring follow-up with a checkbox, so that I can schedule and track necessary follow-up actions.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL display the Mark_as_Follow_Up_Checkbox below the Call_Remarks_TextArea
2. THE Mark_as_Follow_Up_Checkbox SHALL have a label "Mark as Follow Up" next to the checkbox
3. THE Mark_as_Follow_Up_Checkbox SHALL be unchecked by default
4. WHEN the Mark_as_Follow_Up_Checkbox is toggled, THE JustDial_Detail_Screen SHALL update the checkbox state immediately

---

### Requirement 11: Display Follow-Ups Date Field with Date Picker

**User Story:** As a telecaller, I want to schedule a follow-up date using a date picker, so that I can plan when to contact the customer again.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL display the Follow_Ups_Date_Field below the Mark_as_Follow_Up_Checkbox
2. THE Follow_Ups_Date_Field SHALL include a date picker that opens when tapped
3. THE Follow_Ups_Date_Field SHALL be optional and allow empty values
4. WHEN the Mark_as_Follow_Up_Checkbox is unchecked, THE Follow_Ups_Date_Field SHALL be disabled or visually de-emphasized
5. WHEN the Mark_as_Follow_Up_Checkbox is checked, THE Follow_Ups_Date_Field SHALL be enabled and ready for input

---

### Requirement 12: Display Cancel and Save Lead Buttons at Bottom

**User Story:** As a telecaller, I want to save my entered data or cancel the operation with clearly visible buttons at the bottom of the form, so that I can complete or discard the call details efficiently.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL display the Cancel_Button and Save_Lead_Button at the bottom of the form
2. THE Cancel_Button SHALL be positioned on the left side and occupy approximately 50% of the available width
3. THE Save_Lead_Button SHALL be positioned on the right side and occupy approximately 50% of the available width
4. THE Cancel_Button SHALL have a label "Cancel" and a neutral or secondary color scheme
5. THE Save_Lead_Button SHALL have a label "Save Lead" and a primary color scheme
6. WHEN the Cancel_Button is tapped, THE JustDial_Detail_Screen SHALL discard all changes and return to the previous screen
7. WHEN the Save_Lead_Button is tapped, THE JustDial_Detail_Screen SHALL validate all required fields and save the data if validation passes
8. BOTH buttons SHALL have a minimum height of 48 pixels for touch accessibility
9. BOTH buttons SHALL have a minimum spacing of 8 pixels between them

---

### Requirement 13: Validate Required Fields Before Saving

**User Story:** As a telecaller, I want the system to validate that all required fields are filled before saving, so that I can ensure data completeness and avoid incomplete records.

#### Acceptance Criteria

1. WHEN the Save_Lead_Button is tapped, THE JustDial_Detail_Screen SHALL validate that Sub_Category_Dropdown has a selection
2. WHEN the Save_Lead_Button is tapped, THE JustDial_Detail_Screen SHALL validate that Close_Reason_Dropdown has a selection
3. WHEN the Save_Lead_Button is tapped, THE JustDial_Detail_Screen SHALL validate that Item_Category_Dropdown has a selection
4. IF any required field is empty, THEN THE JustDial_Detail_Screen SHALL display a validation error message
5. IF all required fields are filled, THEN THE JustDial_Detail_Screen SHALL proceed with saving the data

---

### Requirement 14: Persist Form Data to Backend

**User Story:** As a telecaller, I want the form data to be saved to the backend system, so that the call details are recorded and available for reporting and follow-up.

#### Acceptance Criteria

1. WHEN the Save_Lead_Button is tapped and all validations pass, THE JustDial_Detail_Screen SHALL send a request to the backend API
2. THE request SHALL include all form field values: phone number, customer name, store, location, function date, call duration, complaint flag, sub-category, close reason, item category, remarks, follow-up flag, and follow-up date
3. WHEN the backend request succeeds, THE JustDial_Detail_Screen SHALL display a success message
4. WHEN the backend request succeeds, THE JustDial_Detail_Screen SHALL return to the previous screen after a brief delay
5. WHEN the backend request fails, THE JustDial_Detail_Screen SHALL display an error message with details about the failure
6. WHEN the backend request fails, THE JustDial_Detail_Screen SHALL retain all entered data so the user can retry

---

### Requirement 15: Apply Design Pattern with Proper Spacing and Visual Hierarchy

**User Story:** As a user, I want the form to follow the design mockup with consistent spacing, icons, and visual hierarchy, so that the interface is intuitive and visually appealing.

#### Acceptance Criteria

1. WHEN the JustDial_Detail_Screen is loaded, THE JustDial_Detail_Screen SHALL apply consistent padding and margins throughout the form
2. THE form fields SHALL be organized in a logical top-to-bottom flow matching the Design_Mockup
3. THE form fields SHALL have appropriate visual spacing (minimum 16 pixels between sections)
4. THE form labels SHALL use a consistent font size and color scheme
5. THE form icons SHALL be positioned consistently to the left of input fields
6. THE Required_Field_Badge indicators SHALL be visually distinct and positioned consistently
7. THE form SHALL follow the color scheme and typography defined in the Design_Mockup

---

### Requirement 16: Support Follow-Up Functionality

**User Story:** As a telecaller, I want to schedule follow-ups directly from the detail screen, so that I can manage customer interactions and ensure timely follow-up actions.

#### Acceptance Criteria

1. WHEN the Mark_as_Follow_Up_Checkbox is checked, THE JustDial_Detail_Screen SHALL enable the Follow_Ups_Date_Field
2. WHEN the Mark_as_Follow_Up_Checkbox is unchecked, THE JustDial_Detail_Screen SHALL disable the Follow_Ups_Date_Field
3. WHEN the Save_Lead_Button is tapped with Mark_as_Follow_Up_Checkbox checked, THE JustDial_Detail_Screen SHALL save the follow-up date to the backend
4. WHEN the Save_Lead_Button is tapped with Mark_as_Follow_Up_Checkbox unchecked, THE JustDial_Detail_Screen SHALL not save a follow-up date
5. THE Follow_Ups_Date_Field SHALL allow selecting any future date using the date picker

