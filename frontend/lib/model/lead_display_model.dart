import 'package:flutter/material.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/category_style.dart';
import 'package:telecaller_app/utils/date_formatter.dart';

/// Display model for leads in the UI
class LeadDisplayModel {
  final String name;
  final String phone;
  final String date;
  final String category;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final LeadModel? leadModel;

  LeadDisplayModel({
    required this.name,
    required this.phone,
    required this.date,
    required this.category,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
    this.leadModel,
  });

  /// Create from LeadModel
  factory LeadDisplayModel.fromLead(LeadModel lead) {
    final style = CategoryStyleHelper.getStyle(lead.category);
    return LeadDisplayModel(
      name: lead.name,
      phone: lead.phone,
      date: DateFormatter.formatDate(lead.createdAt),
      category: lead.category ?? "Follow Up",
      bgColor: style.tagBgColor,
      iconColor: style.iconColor,
      icon: style.icon,
      leadModel: lead,
    );
  }

  /// Convert to map for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "phone": phone,
      "date": date,
      "category": category,
      "bgColor": bgColor,
      "iconColor": iconColor,
      "icon": icon,
      "lead": leadModel,
    };
  }
}
