import 'package:flutter/material.dart';
import 'package:telecaller_app/utils/lead_constants.dart';

/// Category style configuration for UI display
class CategoryStyle {
  final String tag;
  final Color tagColor;
  final Color tagBgColor;
  final IconData icon;
  final Color iconColor;

  const CategoryStyle({
    required this.tag,
    required this.tagColor,
    required this.tagBgColor,
    required this.icon,
    required this.iconColor,
  });
}

/// Utility class to get category styles
class CategoryStyleHelper {
  static CategoryStyle getStyle(String? category) {
    switch (category) {
      case LeadConstants.categoryLossOfSales:
        return const CategoryStyle(
          tag: "Loss of Sale",
          tagColor: Color(0xFFE23434),
          tagBgColor: Color(0xFFFFE8E8),
          icon: Icons.trending_down,
          iconColor: Color(0xFFE23434),
        );
      case LeadConstants.categoryRentOut:
        return const CategoryStyle(
          tag: "Rent Out",
          tagColor: Color(0xFFFFCC00),
          tagBgColor: Color(0xFFFFF7CC),
          icon: Icons.message_outlined,
          iconColor: Color(0xFFFFCC00),
        );
      case LeadConstants.categoryBookingConfirmation:
        return const CategoryStyle(
          tag: "Booking Confirmation",
          tagColor: Color(0xff56BE6B),
          tagBgColor: Color(0xFFD4F5DA),
          icon: Icons.flag_outlined,
          iconColor: Color(0xff56BE6B),
        );
      case LeadConstants.categoryJustDial:
        return const CategoryStyle(
          tag: "Just Dial",
          tagColor: Color(0xFFF37927),
          tagBgColor: Color(0xFFFFE8D5),
          icon: Icons.headset_mic_outlined,
          iconColor: Color(0xFFF37927),
        );
      default:
        return const CategoryStyle(
          tag: "Follow Up",
          tagColor: Color(0xFF7C5DFF),
          tagBgColor: Color(0xFFE8E3FF),
          icon: Icons.phone_outlined,
          iconColor: Color(0xFF7C5DFF),
        );
    }
  }

  static Map<String, dynamic> toMap(String? category) {
    final style = getStyle(category);
    return {
      "tag": style.tag,
      "tagColor": style.tagColor,
      "tagBgColor": style.tagBgColor,
      "icon": style.icon,
      "iconColor": style.iconColor,
    };
  }
}
