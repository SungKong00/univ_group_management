import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../providers/place_calendar_provider.dart';
import 'place_selector_popover.dart';

/// Button that triggers the place selector popover
/// Displays "장소 선택" with a count badge and shows popover on click
class PlaceSelectorButton extends ConsumerStatefulWidget {
  const PlaceSelectorButton({super.key});

  @override
  ConsumerState<PlaceSelectorButton> createState() =>
      _PlaceSelectorButtonState();
}

class _PlaceSelectorButtonState extends ConsumerState<PlaceSelectorButton> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    // Remove overlay without calling setState to avoid lifecycle issues
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _togglePopover() {
    if (_overlayEntry != null) {
      _removePopover();
    } else {
      _showPopover();
    }
  }

  void _showPopover() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    // Popover width from constraints
    const popoverWidth = 400.0;

    // Check if popover would overflow on the right
    final wouldOverflowRight = offset.dx + popoverWidth > screenWidth;

    // Determine anchors based on available space
    final targetAnchor = wouldOverflowRight
        ? Alignment.bottomRight
        : Alignment.bottomLeft;
    final followerAnchor = wouldOverflowRight
        ? Alignment.topRight
        : Alignment.topLeft;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Barrier to dismiss on outside click
          Positioned.fill(
            child: GestureDetector(
              onTap: _removePopover,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Popover positioned below the button
          Positioned(
            width: popoverWidth,
            child: CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: targetAnchor,
              followerAnchor: followerAnchor,
              offset: Offset(0, size.height + 8), // 8px gap below button
              child: PlaceSelectorPopover(onClose: _removePopover),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removePopover() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeCalendarProvider);
    final isOpen = _overlayEntry != null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: OutlinedButton(
        onPressed: _togglePopover,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 8,
          ),
          side: BorderSide(
            color: isOpen ? AppColors.brand : AppColors.neutral300,
            width: isOpen ? 2 : 1,
          ),
          backgroundColor: isOpen
              ? AppColors.brandLight.withValues(alpha: 0.1)
              : Colors.transparent,
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.place,
              size: 18,
              color: isOpen ? AppColors.brand : AppColors.neutral600,
            ),
            const SizedBox(width: 6),
            Text(
              '장소',
              style: AppTheme.bodySmall.copyWith(
                color: isOpen ? AppColors.brand : AppColors.neutral700,
                fontWeight: isOpen ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (state.selectedPlaceIds.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(
                    AppComponents.badgeRadius,
                  ),
                ),
                child: Text(
                  '${state.selectedPlaceIds.length}',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 18,
              color: isOpen ? AppColors.brand : AppColors.neutral600,
            ),
          ],
        ),
      ),
    );
  }
}
