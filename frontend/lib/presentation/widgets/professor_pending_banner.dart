import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfessorPendingBanner extends StatelessWidget {
  const ProfessorPendingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final show = user?.role == 'PROFESSOR' && (user?.professorStatus == 'PENDING');
        if (!show) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFFFFF4E5),
          child: Row(
            children: const [
              Icon(Icons.info_outline, color: Color(0xFF8B5E00)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '교수 권한 승인 대기 중입니다. 승인되면 알려드릴게요.',
                  style: TextStyle(color: Color(0xFF8B5E00)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

