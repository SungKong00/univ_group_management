import 'package:flutter/material.dart';

class SkeletonUI {
  static Widget tile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, color: Colors.black12),
                const SizedBox(height: 6),
                Container(height: 10, width: 140, color: Colors.black12),
              ],
            ),
          )
        ],
      ),
    );
  }

  static Widget bigCard() {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 16, width: 180, color: Colors.black12),
              const SizedBox(height: 12),
              Expanded(child: Container(color: Colors.black12)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget chipSkeleton() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFD1D5DB),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 72, height: 12, color: const Color(0xFFD1D5DB)),
        ],
      ),
    );
  }

  static Widget activitySkeleton(String meta) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          const Icon(Icons.bolt_outlined, size: 20, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(height: 12, width: 160, color: const Color(0xFFD1D5DB)),
            ),
          )
        ],
      ),
    );
  }

  static Widget dot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
      ),
    );
  }
}