import 'package:flutter/material.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/date_formatter.dart';
import 'package:telecaller_app/utils/lead_constants.dart';
import 'package:telecaller_app/view/lead_screen/return_lead_details_screen.dart';
import 'package:telecaller_app/view/lead_screen/booking_confirmation_detail_screen.dart';
import 'package:telecaller_app/view/reports_screens/report_details_screen/loss_of_sale_detail_screen.dart';
import 'package:telecaller_app/view/lead_screen/lead_detail_screen.dart';

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

    // Special handling for Feedback calls
    if (category == LeadConstants.categoryRentOut || category == "Return") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReturnLeadDetailsScreen(lead: lead),
        ),
      );
      return;
    }

    // Special handling for Booking Confirmation
    if (category == LeadConstants.categoryBookingConfirmation ||
        category == "Booking Confirmation") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationDetailScreen(lead: lead),
        ),
      );
      return;
    }

    // Special handling for Enquiry, Booked, and Loss of Sale leads from Lead Screen
    if (category == LeadConstants.categoryEnquiry ||
        category == LeadConstants.categoryBooked ||
        category == LeadConstants.categoryLossOfSales ||
        category == "Loss of Sale" ||
        category == "enquiry" ||
        category == "booked") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LeadDetailScreen(lead: lead),
        ),
      );
      return;
    }

    // Prepare contact data
    final repository = LeadRepository();
    Map<String, dynamic> contactData = {
      "id": lead.id,
      "name": lead.name,
      "phone": lead.phone,
      "date": formattedDate,
      "visitDate": formattedDate,
      "functionDate": "Not available",
      "attendedBy": "Not available",
      "reasonFromStore": lead.reason ?? "No reason provided",
      "storeName": lead.location ?? "Zorucci Edappally",
    };

    // Add booking confirmation specific data if available
    if (category == LeadConstants.categoryBookingConfirmation ||
        category == "Booking Confirmation") {
      final bookingData = repository.getBookingConfirmationData(lead.id);
      if (bookingData != null) {
        contactData["bookingNo"] =
            bookingData['bookingNumber'] ?? "Not available";

        // Format enquiry date
        if (bookingData['enquiryDate'] != null) {
          try {
            final enquiryDate = DateTime.parse(bookingData['enquiryDate']);
            contactData["enquiryDate"] = DateFormatter.formatDate(enquiryDate);
          } catch (e) {
            contactData["enquiryDate"] =
                bookingData['enquiryDate'] ?? "Not available";
          }
        } else {
          contactData["enquiryDate"] = formattedDate;
        }

        // Format function date
        if (bookingData['functionDate'] != null) {
          try {
            final functionDate = DateTime.parse(bookingData['functionDate']);
            contactData["functionDate"] = DateFormatter.formatDate(
              functionDate,
            );
          } catch (e) {
            contactData["functionDate"] =
                bookingData['functionDate'] ?? "Not available";
          }
        } else {
          contactData["functionDate"] = "Not available";
        }

        // Add security amount if available
        if (bookingData['securityAmount'] != null) {
          contactData["securityAmount"] = bookingData['securityAmount'];
        } else {
          contactData["securityAmount"] = "Not available";
        }
      } else {
        // Fallback if booking data not found
        contactData["bookingNo"] = "Not available";
        contactData["enquiryDate"] = formattedDate;
        contactData["functionDate"] = "Not available";
        contactData["securityAmount"] = "Not available";
      }
    }

    // Navigate to regular details screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder:
    //         (context) => DetailsScreen(
    //           contact: contactData,
    //           callTypeIndex: callTypeIndex,
    //         ),
    //   ),
    // );
  }
}
