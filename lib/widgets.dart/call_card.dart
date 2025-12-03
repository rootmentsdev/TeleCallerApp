import 'package:flutter/material.dart';
import 'package:telecaller_app/utils/text_constant.dart' show TextConstant;

class CallCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String count;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          width: double.infinity,
          child: Row(
            children: [
              Container(
                height: double.infinity,
                width: 39,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: bgColor,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: TextConstant.dmSansMedium,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: TextConstant.dmSansRegular,
                        color: const Color(0xff797979),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: double.infinity,
                width: 39,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: bgColor,
                ),
                child: Center(
                  child: Text(count, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
