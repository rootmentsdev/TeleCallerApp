import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:telecaller_app/model/lead_model.dart';
import 'package:telecaller_app/utils/color_constant.dart';
import 'package:telecaller_app/utils/text_constant.dart';
import 'package:telecaller_app/utils/format_helper.dart';
import 'package:telecaller_app/utils/lead_constants.dart';

class StarredCallsDetailsScreen extends StatelessWidget {
  final LeadModel lead;
  final String formattedDate;

  const StarredCallsDetailsScreen({
    super.key,
    required this.lead,
    required this.formattedDate,
  });

  String get screenTitle {
    final category = lead.category ?? "";
    if (category == LeadConstants.categoryRentOut || category == "Return") {
      return "Marked Calls | Rent Out Feedback";
    } else if (category == LeadConstants.categoryLossOfSales ||
        category == "Loss of Sale") {
      return "Marked Calls | Loss of Sale";
    } else if (category == LeadConstants.categoryBookingConfirmation ||
        category == "Booking Confirmation") {
      return "Marked Calls | Booking Confirmation";
    }
    return "Marked Calls";
  }

  String get storeName {
    if (lead.brand != null && lead.location != null) {
      return "${lead.brand} - ${lead.location}";
    } else if (lead.location != null) {
      return lead.location!;
    } else if (lead.brand != null) {
      return lead.brand!;
    }
    return "Zorucci Edappally";
  }

  /// Get icon based on lead category
  IconData get _getCategoryIcon {
    final category = lead.category ?? "";
    if (category == LeadConstants.categoryRentOut || category == "Return") {
      return Icons.assignment_return_rounded;
    } else if (category == LeadConstants.categoryLossOfSales ||
        category == "Loss of Sale") {
      return Icons.trending_down_rounded;
    } else if (category == LeadConstants.categoryBookingConfirmation ||
        category == "Booking Confirmation") {
      return Icons.event_available_rounded;
    }
    return Icons.person_rounded;
  }

  /// Get color based on lead category
  Color get _getCategoryColor {
    final category = lead.category ?? "";
    if (category == LeadConstants.categoryRentOut || category == "Return") {
      return const Color(0xFFFDD835); // Yellow
    } else if (category == LeadConstants.categoryLossOfSales ||
        category == "Loss of Sale") {
      return const Color(0xFFE53935); // Red
    } else if (category == LeadConstants.categoryBookingConfirmation ||
        category == "Booking Confirmation") {
      return const Color(0xFF43A047); // Green
    }
    return const Color(0xFF1E88E5); // Blue (default)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.primaryColor,
      body: Column(
        children: [
          // Enhanced Header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorConstant.primaryColor,
                  ColorConstant.primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back button positioned on the left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Centered title and subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 30, bottom: 10),
                        child: Text(
                          screenTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: TextConstant.dmSansMedium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          storeName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontFamily: TextConstant.dmSansRegular,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // Star icon positioned on the right
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Information Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: _getCategoryColor.withValues(
                              alpha: 0.2,
                            ),
                            child: Icon(
                              _getCategoryIcon,
                              color: _getCategoryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lead.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: TextConstant.dmSansMedium,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lead.phone,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ColorConstant.grey,
                                    fontFamily: TextConstant.dmSansRegular,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Call Date and Duration
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: TextConstant.dmSansRegular,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (lead.callDuration != null &&
                                  lead.callDuration! > 0) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    FormatHelper.formatCallDuration(
                                      lead.callDuration!,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category-specific details
                    _buildCategoryDetails(),

                    const SizedBox(height: 24),

                    // Call Status and Lead Status
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusBadge(
                            "CALL STATUS",
                            lead.callStatus ?? "Not Called",
                            const Color(0xFF43A047),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatusBadge(
                            "LEAD STATUS",
                            lead.leadStatus ?? "No Status",
                            const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Reason (for Loss of Sale)
                    if (lead.category == LeadConstants.categoryLossOfSales ||
                        lead.category == "Loss of Sale")
                      if (lead.reason != null && lead.reason!.isNotEmpty) ...[
                        _buildDetailRow(
                          "REASON",
                          lead.reason!,
                          isMultiline: true,
                        ),
                        const SizedBox(height: 16),
                      ],

                    // Remarks
                    _buildDetailRow(
                      "REMARKS",
                      lead.reason ?? "No remarks",
                      isMultiline: true,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Enhanced Footer with Share Details button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _shareDetails(context),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: const Text(
                    "Share Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: TextConstant.dmSansMedium,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstant.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDetails() {
    final category = lead.category ?? "";

    // Return/Rent Out Feedback
    if (category == LeadConstants.categoryRentOut || category == "Return") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            "BOOKING NO",
            lead.id.substring(0, 10), // Use first 10 chars of ID as booking no
          ),
          const SizedBox(height: 8),
          _buildDetailRow("RETURN DATE", formattedDate),
          const SizedBox(height: 8),
          _buildDetailRow("ATTENDED BY", storeName),
          const SizedBox(height: 8),
          _buildDetailRow("SECURITY AMOUNT", "Refunded"),
          const SizedBox(height: 8),
          // Rating
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "RATING",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff171717),
                  fontFamily: TextConstant.dmSansRegular,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star_rounded,
                    size: 20,
                    color: index < 1 ? Colors.amber : Colors.grey[300],
                  );
                }),
              ),
            ],
          ),
        ],
      );
    }

    // Booking Confirmation
    if (category == LeadConstants.categoryBookingConfirmation ||
        category == "Booking Confirmation") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow("BOOKING NO", lead.id.substring(0, 10)),
          const SizedBox(height: 8),
          _buildDetailRow("RETURN DATE", formattedDate),
          const SizedBox(height: 8),
          _buildDetailRow("ATTENDED BY", storeName),
          const SizedBox(height: 8),
          _buildDetailRow("SECURITY AMOUNT", "Refunded"),
          const SizedBox(height: 8),
          // Rating
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "RATING",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff171717),
                  fontFamily: TextConstant.dmSansRegular,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star_rounded,
                    size: 20,
                    color: index < 1 ? Colors.amber : Colors.grey[300],
                  );
                }),
              ),
            ],
          ),
        ],
      );
    }

    // Loss of Sale
    if (category == LeadConstants.categoryLossOfSales ||
        category == "Loss of Sale") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildDetailRow("CALL DATE", formattedDate)),
              const SizedBox(width: 16),
              Expanded(child: _buildDetailRow("VISIT DATE", formattedDate)),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow("FUNCTION DATE", formattedDate),
          const SizedBox(height: 8),
          _buildDetailRow("ATTENDED BY", storeName),
          const SizedBox(height: 8),
          _buildDetailRow(
            "REASON COLLECTED FROM STORE",
            lead.reason ?? "No reason provided",
            isMultiline: true,
          ),
        ],
      );
    }

    // General/Default
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildDetailRow("CALL DATE", formattedDate)),
            const SizedBox(width: 16),
            Expanded(child: _buildDetailRow("VISIT DATE", formattedDate)),
          ],
        ),
        const SizedBox(height: 8),
        _buildDetailRow("FUNCTION DATE", formattedDate),
        const SizedBox(height: 8),
        _buildDetailRow("ATTENDED BY", storeName),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontFamily: TextConstant.dmSansRegular,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
            fontFamily: TextConstant.dmSansMedium,
            height: isMultiline ? 1.5 : 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, String value, Color color) {
    final r = ((color.value >> 16) & 0xFF);
    final g = ((color.value >> 8) & 0xFF);
    final b = (color.value & 0xFF);

    final darkerColor = Color.fromARGB(
      255,
      (r * 0.7).round().clamp(0, 255),
      (g * 0.7).round().clamp(0, 255),
      (b * 0.7).round().clamp(0, 255),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontFamily: TextConstant.dmSansRegular,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: darkerColor,
              fontFamily: TextConstant.dmSansMedium,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareDetails(BuildContext context) async {
    try {
      final category = lead.category ?? "";
      String categoryName = "Marked Call";

      if (category == LeadConstants.categoryRentOut || category == "Return") {
        categoryName = "Rent Out Feedback";
      } else if (category == LeadConstants.categoryLossOfSales ||
          category == "Loss of Sale") {
        categoryName = "Loss of Sale";
      } else if (category == LeadConstants.categoryBookingConfirmation ||
          category == "Booking Confirmation") {
        categoryName = "Booking Confirmation";
      }

      // Build comprehensive share text
      final StringBuffer shareText = StringBuffer();
      shareText.writeln('⭐ $categoryName Details');
      shareText.writeln('');
      shareText.writeln('👤 Name: ${lead.name}');
      shareText.writeln('📞 Phone: ${lead.phone}');
      shareText.writeln('🏪 Store: $storeName');
      shareText.writeln('📅 Call Date: $formattedDate');

      if (lead.callDuration != null && lead.callDuration! > 0) {
        shareText.writeln(
          '⏱️ Duration: ${FormatHelper.formatCallDuration(lead.callDuration!)}',
        );
      }

      shareText.writeln(
        '📊 Call Status: ${lead.callStatus ?? "Not Called"}',
      );
      shareText.writeln(
        '📈 Lead Status: ${lead.leadStatus ?? "No Status"}',
      );

      // Add category-specific details
      if (category == LeadConstants.categoryRentOut || category == "Return") {
        shareText.writeln('📋 Booking No: ${lead.id.substring(0, 10)}');
        shareText.writeln('📅 Return Date: $formattedDate');
        shareText.writeln('💰 Security Amount: Refunded');
      } else if (category == LeadConstants.categoryLossOfSales ||
          category == "Loss of Sale") {
        if (lead.reason != null && lead.reason!.isNotEmpty) {
          shareText.writeln('📝 Reason Collected From Store: ${lead.reason}');
        }
      } else if (category == LeadConstants.categoryBookingConfirmation ||
          category == "Booking Confirmation") {
        shareText.writeln('📋 Booking No: ${lead.id.substring(0, 10)}');
        shareText.writeln('📅 Return Date: $formattedDate');
        shareText.writeln('💰 Security Amount: Refunded');
      }

      if (lead.reason != null && lead.reason!.isNotEmpty) {
        shareText.writeln('💬 Remarks: ${lead.reason}');
      } else {
        shareText.writeln('💬 Remarks: No remarks');
      }

      shareText.writeln('');
      shareText.writeln('Shared from Telecaller App');

      final shareTextString = shareText.toString();

      // Try to share using share_plus
      try {
        await Share.share(shareTextString);
        
        // Show feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening share dialog...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (shareError) {
        // If share_plus fails, copy to clipboard as fallback
        print('Share_plus failed: $shareError');
        
        try {
          await Clipboard.setData(ClipboardData(text: shareTextString));
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Details copied to clipboard!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (clipboardError) {
          // If clipboard also fails, show error
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Unable to share. Please restart the app and try again.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Copy Text',
                  textColor: Colors.white,
                  onPressed: () async {
                    try {
                      await Clipboard.setData(
                        ClipboardData(text: shareTextString),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Details copied to clipboard!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      print('Clipboard copy failed: $e');
                    }
                  },
                ),
              ),
            );
          }
          print('Error sharing details: $shareError');
          print('Clipboard fallback also failed: $clipboardError');
        }
      }
    } catch (e) {
      // Show error message if something else fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Error in _shareDetails: $e');
    }
  }
}
