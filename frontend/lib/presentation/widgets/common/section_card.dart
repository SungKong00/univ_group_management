import 'package:flutter/material.dart';
import 'skeleton_ui.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget>? children;
  final VoidCallback? onSeeAll;
  final bool isLoading;
  final int skeletonCount;

  const SectionCard({
    super.key,
    required this.title,
    this.children,
    this.onSeeAll,
    this.isLoading = false,
    this.skeletonCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: onSeeAll,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('모두 보기'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              ...List.generate(skeletonCount, (_) => SkeletonUI.tile())
            else if (children != null)
              ...children!
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}