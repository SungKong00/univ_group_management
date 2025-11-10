import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Unread Message Divider Widget
///
/// Displays "읽지 않은 글" with left/right divider lines
class UnreadMessageDivider extends StatelessWidget {
  const UnreadMessageDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '읽지 않은 게시글입니다',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.brand.withOpacity(0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                '읽지 않은 글',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: AppColors.brand,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.brand.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
