import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/local_storage.dart';
import '../../providers/timetable_provider.dart';
import '../../widgets/common/compact_tab_bar.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/timetable_tab.dart';

/// LocalStorage Provider
final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage.instance;
});

/// 캘린더 페이지 (시간표 + 캘린더)
///
/// 두 개의 탭으로 구성:
/// - TimetableTab: 개인 시간표 (주간 뷰, 반복 일정)
/// - CalendarTab: 개인 캘린더 (월간/주간/일간 뷰, 단일 일정)
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// 정적 변수: 마지막 탭 인덱스 (메모리에 보존)
  static int? _lastTabIndex;

  @override
  void initState() {
    super.initState();

    // TabController 즉시 초기화 (동기)
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _lastTabIndex ?? 0,
    );

    // 탭 변경 리스너 등록
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        _lastTabIndex = _tabController.index;
        // 비동기로 LocalStorage에 저장 (초기화 블로킹 안 함)
        ref
            .read(localStorageProvider)
            .saveLastCalendarTab(_tabController.index);
      }
    });

    // LocalStorage에서 저장된 탭 인덱스 복원 (비동기, 백그라운드)
    _restoreTabFromLocalStorage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timetableStateProvider.notifier).loadSchedules();
    });
  }

  /// LocalStorage에서 마지막 탭 인덱스 복원 (비동기)
  Future<void> _restoreTabFromLocalStorage() async {
    if (_lastTabIndex != null) return; // 이미 정적 변수에 값이 있으면 스킵

    final localStorage = ref.read(localStorageProvider);
    final savedTab = await localStorage.getLastCalendarTab();

    if (savedTab != null && mounted && savedTab != _tabController.index) {
      _lastTabIndex = savedTab;
      _tabController.index = savedTab;
    }
  }

  @override
  void dispose() {
    // CalendarEventsNotifier의 dispose에서 스냅샷이 자동 저장됨
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CompactTabBar(
            controller: _tabController,
            tabs: const [
              CompactTab(label: '시간표'),
              CompactTab(label: '캘린더'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [TimetableTab(), CalendarTab()],
            ),
          ),
        ],
      ),
    );
  }
}
