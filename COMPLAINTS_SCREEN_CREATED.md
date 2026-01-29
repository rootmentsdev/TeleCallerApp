# Complaints Screen - UI Created

## Overview
Created a new Complaints screen that displays recent complaints with filtering and detailed view options.

## Features

### Header Section
- Dark blue header with back button and notification icon
- "Complaints" title
- Notification bell icon

### Recent Complaints Section
- Shows total complaint count in red
- Displays "14 Complaints" or dynamic count

### Filters
- Store dropdown (All Stores, Select Store)
- Date picker calendar icon
- Responsive layout

### Complaint Cards

#### Expanded View (First Card)
- Customer name and phone number
- Complaint type badge (Enquiry)
- Date and time
- Store & Location
- Function Date
- Sub Category
- Call Remarks / Notes (full text)
- Rounded border with padding

#### Collapsed View (Other Cards)
- Customer name and phone
- Date/time on right
- Sub Category in red
- Remarks preview (truncated with ellipsis)
- Store name
- "Details" link with arrow icon
- Lighter border

### Data Structure
Each complaint contains:
- `name`: Customer name
- `phone`: Phone number
- `type`: Complaint type (Enquiry, etc.)
- `date`: Date and time
- `store`: Store location
- `functionDate`: Function date (optional)
- `subCategory`: Complaint category
- `remarks`: Detailed notes
- `isExpanded`: Toggle for expanded/collapsed view

## File Location
`frontend/lib/view/complaints_screen/complaints_screen.dart`

## UI Components
- Custom header with back button
- Store filter dropdown
- Date picker button
- Expandable complaint cards
- Detail rows with labels and values
- Responsive scrollable list

## Styling
- Primary color: Dark blue header
- Accent color: Red for complaint count and sub category
- Blue badges for complaint type
- Grey text for secondary information
- Rounded corners (12-16px)
- Proper spacing and padding

## Next Steps
1. Connect to backend API to fetch complaints
2. Implement store filter functionality
3. Implement date picker for filtering
4. Create complaint detail screen
5. Add navigation to detail screen from "Details" link
6. Implement expand/collapse toggle
7. Add complaint status management
8. Integrate with complaint controller

## Sample Data
Currently using hardcoded sample data with 3 complaints:
- All from "Abhiram" (+91 98765 43210)
- All with "Product Damage" sub category
- All from "Zorucci Edappally" store
- Dated 18 Jan 2026

Replace with API data when backend integration is ready.
