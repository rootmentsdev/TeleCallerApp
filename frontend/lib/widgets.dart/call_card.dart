import 'package:flutter/material.dart';
import 'package:telecaller_app/utils/text_constant.dart' show TextConstant;

/// Reusable call card widget for displaying call information
class CallCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String count;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  // Design constants
  static const double _cardHeight = 50.0;
  static const double _borderRadius = 12.0;
  static const double _iconContainerWidth = 39.0;
  static const double _spacing = 12.0;
  static const double _verticalPadding = 8.0;
  static const double _titleFontSize = 14.0;
  static const double _subtitleFontSize = 12.0;
  static const double _countFontSize = 14.0;
  static const Color _subtitleColor = Color(0xff797979);

  const CallCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_borderRadius),
        child: Container(
          height: _cardHeight,
          width: double.infinity,
          child: Row(
            children: [
              _buildIconContainer(),
              const SizedBox(width: _spacing),
              Expanded(child: _buildContent()),
              _buildCountContainer(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the icon container on the left side
  Widget _buildIconContainer() {
    return Container(
      height: double.infinity,
      width: _iconContainerWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        color: bgColor,
      ),
      child: Icon(icon, color: iconColor),
    );
  }

  /// Builds the content section with title and subtitle
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: TextConstant.dmSansMedium,
            fontSize: _titleFontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: _subtitleFontSize,
            fontFamily: TextConstant.dmSansRegular,
            color: _subtitleColor,
          ),
        ),
      ],
    );
  }

  /// Builds the count container on the right side
  Widget _buildCountContainer() {
    return Container(
      height: double.infinity,
      width: _iconContainerWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        color: bgColor,
      ),
      child: Center(
        child: Text(count, style: const TextStyle(fontSize: _countFontSize)),
      ),
    );
  }
}
