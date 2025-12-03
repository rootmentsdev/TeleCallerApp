import 'package:flutter/material.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/view/details_screen.dart';
import 'package:telecaller_app/view/reports_screens/just_dial_details_screen.dart';

/// Helper class for navigation logic
class NavigationHelper {
  /// Get call type index based on category
  static int getCallTypeIndex(String? category) {
    switch (category) {
      case LeadConstants.categoryLossOfSales:
      case "Loss of Sale": // Handle variant
        return 1;
      case LeadConstants.categoryBookingConfirmation:
      case "Booking Confirmation": // Handle variant
        return 3;
      default:
        return 0;
    }
  }

  /// Navigate to appropriate details screen based on category
  static void navigateToDetails(
    BuildContext context,
    LeadModel lead,
    String formattedDate,
  ) {
    final category = lead.category ?? "";
    final callTypeIndex = getCallTypeIndex(category);

    // Special handling for Just Dial
    if (category == LeadConstants.categoryJustDial ||
        category == "Just Dial Enquiry") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => JustDialDetailsScreen(
                contact: {
                  "name": lead.name,
                  "phone": lead.phone,
                  "date": formattedDate,
                  "enquiryDate": formattedDate,
                  "functionDate": "Not available",
                  "storeName": lead.location ?? "Zorucci Edappally",
                },
              ),
        ),
      );
      return;
    }

    // Navigate to regular details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DetailsScreen(
              contact: {
                "id": lead.id,
                "name": lead.name,
                "phone": lead.phone,
                "date": formattedDate,
                "visitDate": formattedDate,
                "functionDate": "Not available",
                "attendedBy": "Not available",
                "reasonFromStore": lead.reason ?? "No reason provided",
                "storeName": lead.location ?? "Zorucci Edappally",
              },
              callTypeIndex: callTypeIndex,
            ),
      ),
    );
  }
}
