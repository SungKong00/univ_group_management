/// PersonalScheduleAdapter 데이터 변환 테스트
///
/// 이 테스트는 PersonalScheduleAdapter의 핵심 기능을 검증합니다:
/// 1. PersonalSchedule ↔ Event 양방향 변환
/// 2. 시간 계산 (TimeOfDay → 15분 슬롯 인덱스)
/// 3. 요일 매핑 (DayOfWeek → day index)
/// 4. 색상 처리 및 기본값
/// 5. ID 추출 및 이벤트 타입 식별
///
/// **핵심 변환 로직**:
/// - 15분 슬롯: slot = hour * 4 + (minute / 15)
/// - 요일: Monday = 0, Sunday = 6
/// - 색상: 개인 일정은 팔레트에서 선택, 외부 이벤트는 null
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/calendar_models.dart';
import 'package:frontend/presentation/adapters/personal_schedule_adapter.dart';

void main() {
  group('PersonalScheduleAdapter', () {
    /// 테스트 기준 주차: 2025년 11월 3일 월요일
    final weekStart = DateTime(2025, 11, 3);

    group('toEvent - PersonalSchedule → Event 변환', () {
      test('기본 정보 변환: ID, 제목, 요일, 시간', () {
        // Given: 월요일 09:00-10:30 데이터베이스 설계
        final schedule = PersonalSchedule(
          id: 42,
          title: 'Database Design',
          dayOfWeek: DayOfWeek.monday,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 30),
          location: 'Engineering Building',
          color: kPersonalScheduleColors[0],
        );

        // When: toEvent 호출
        final event = PersonalScheduleAdapter.toEvent(schedule, weekStart);

        // Then: 변환된 Event 검증
        expect(event.id, 'ps-42');
        expect(event.title, 'Database Design');
        expect(event.start.day, 0); // Monday = 0
        expect(event.start.slot, 36); // 9:00 = 9 * 4 + 0
        expect(event.end.slot, 41); // 10:30 = 10 * 4 + 2, exclusive end -1
      });

      test('TimeOfDay를 DateTime으로 정확히 변환', () {
        // Given: 수요일 14:30-16:00
        final schedule = PersonalSchedule(
          id: 1,
          title: 'Meeting',
          dayOfWeek: DayOfWeek.wednesday,
          startTime: const TimeOfDay(hour: 14, minute: 30),
          endTime: const TimeOfDay(hour: 16, minute: 0),
          color: kPersonalScheduleColors[1],
        );

        // When
        final event = PersonalScheduleAdapter.toEvent(schedule, weekStart);

        // Then: 정확한 날짜/시간 검증
        expect(event.startTime, DateTime(2025, 11, 5, 14, 30));
        expect(event.endTime, DateTime(2025, 11, 5, 16, 0));
      });

      test('모든 요일을 올바르게 매핑 (월-일)', () {
        // Given: 7개 요일의 테스트 케이스
        final days = [
          (DayOfWeek.monday, 0),
          (DayOfWeek.tuesday, 1),
          (DayOfWeek.wednesday, 2),
          (DayOfWeek.thursday, 3),
          (DayOfWeek.friday, 4),
          (DayOfWeek.saturday, 5),
          (DayOfWeek.sunday, 6),
        ];

        // When/Then: 각 요일 검증
        for (final (dayOfWeek, expectedIndex) in days) {
          final schedule = PersonalSchedule(
            id: expectedIndex + 1,
            title: 'Test $dayOfWeek',
            dayOfWeek: dayOfWeek,
            startTime: const TimeOfDay(hour: 10, minute: 0),
            endTime: const TimeOfDay(hour: 11, minute: 0),
            color: kPersonalScheduleColors[0],
          );

          final event = PersonalScheduleAdapter.toEvent(schedule, weekStart);

          expect(event.start.day, expectedIndex,
              reason: 'Day index for $dayOfWeek should be $expectedIndex');
        }
      });

      test('다양한 시간에서 슬롯 인덱스 정확히 계산', () {
        // Given: 자정부터 23:45까지 여러 시간대
        final testCases = [
          (const TimeOfDay(hour: 0, minute: 0), 0), // Midnight
          (const TimeOfDay(hour: 9, minute: 0), 36), // 9:00 AM
          (const TimeOfDay(hour: 9, minute: 15), 37), // 9:15 AM
          (const TimeOfDay(hour: 9, minute: 30), 38), // 9:30 AM
          (const TimeOfDay(hour: 9, minute: 45), 39), // 9:45 AM
          (const TimeOfDay(hour: 14, minute: 30), 58), // 2:30 PM
          (const TimeOfDay(hour: 23, minute: 45), 95), // 11:45 PM
        ];

        // When/Then: 각 시간대 슬롯 계산 검증
        for (final (time, expectedSlot) in testCases) {
          final schedule = PersonalSchedule(
            id: 1,
            title: 'Test',
            dayOfWeek: DayOfWeek.monday,
            startTime: time,
            endTime: const TimeOfDay(hour: 23, minute: 59),
            color: kPersonalScheduleColors[0],
          );

          final event = PersonalScheduleAdapter.toEvent(schedule, weekStart);

          expect(event.start.slot, expectedSlot,
              reason:
                  'Slot for ${time.hour}:${time.minute} should be $expectedSlot');
        }
      });
    });

    group('fromEvent - Event → PersonalScheduleRequest 변환', () {
      test('기본 정보 역변환: 제목, 요일, 시간, 위치, 색상', () {
        // Given: Event (수요일 14:00-15:45)
        final event = (
          id: 'ps-42',
          title: 'Team Meeting',
          start: (day: 2, slot: 56),
          end: (day: 2, slot: 63),
          startTime: DateTime(2025, 11, 5, 14, 0),
          endTime: DateTime(2025, 11, 5, 15, 45),
          color: null,
        );

        // When
        final request = PersonalScheduleAdapter.fromEvent(
          event,
          weekStart,
          location: 'Meeting Room A',
          color: kPersonalScheduleColors[2],
        );

        // Then: 모든 필드 검증
        expect(request.title, 'Team Meeting');
        expect(request.dayOfWeek, DayOfWeek.wednesday);
        expect(request.startTime, const TimeOfDay(hour: 14, minute: 0));
        expect(request.endTime, const TimeOfDay(hour: 15, minute: 45));
        expect(request.location, 'Meeting Room A');
        expect(request.color, kPersonalScheduleColors[2]);
      });

      test('색상 미지정 시 기본값(Blue)으로 설정', () {
        // Given: 색상 미지정 Event
        final event = (
          id: 'ps-1',
          title: 'Test',
          start: (day: 0, slot: 0),
          end: (day: 0, slot: 4),
          startTime: DateTime(2025, 11, 3, 0, 0),
          endTime: DateTime(2025, 11, 3, 1, 0),
          color: null,
        );

        // When
        final request = PersonalScheduleAdapter.fromEvent(event, weekStart);

        // Then: 기본 색상(파란색) 적용
        expect(request.color, kPersonalScheduleColors[0]);
      });

      test('모든 요일을 올바르게 역매핑 (index → DayOfWeek)', () {
        // Given: 7개 요일 인덱스
        // When/Then: 각 인덱스 검증
        for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
          final event = (
            id: 'ps-$dayIndex',
            title: 'Test',
            start: (day: dayIndex, slot: 36),
            end: (day: dayIndex, slot: 40),
            startTime: DateTime(2025, 11, 3 + dayIndex, 9, 0),
            endTime: DateTime(2025, 11, 3 + dayIndex, 10, 0),
            color: null,
          );

          final request = PersonalScheduleAdapter.fromEvent(event, weekStart);

          expect(request.dayOfWeek, DayOfWeek.values[dayIndex],
              reason:
                  'Day index $dayIndex should map to ${DayOfWeek.values[dayIndex]}');
        }
      });
    });

    group('extractScheduleId - ID 추출', () {
      test('유효한 ID 형식에서 숫자만 추출 (ps-NNN → NNN)', () {
        // Given/When/Then: 유효한 ID 형식 검증
        expect(PersonalScheduleAdapter.extractScheduleId('ps-42'), 42);
        expect(PersonalScheduleAdapter.extractScheduleId('ps-1'), 1);
        expect(PersonalScheduleAdapter.extractScheduleId('ps-999'), 999);
      });

      test('유효하지 않은 형식은 null 반환', () {
        // Given/When/Then: 무효한 ID 형식 검증
        expect(PersonalScheduleAdapter.extractScheduleId('ext-42'), null);
        expect(PersonalScheduleAdapter.extractScheduleId('42'), null);
        expect(PersonalScheduleAdapter.extractScheduleId('ps-'), null);
        expect(PersonalScheduleAdapter.extractScheduleId('ps-abc'), null);
      });
    });

    group('isPersonalScheduleEvent - 이벤트 타입 식별', () {
      test('ps- 접두사 이벤트는 개인 일정으로 식별', () {
        // Given: ps-로 시작하는 Event
        final psEvent = (
          id: 'ps-42',
          title: 'Test',
          start: (day: 0, slot: 0),
          end: (day: 0, slot: 4),
          startTime: null,
          endTime: null,
          color: null,
        );

        // When/Then
        expect(
            PersonalScheduleAdapter.isPersonalScheduleEvent(psEvent), true);
      });

      test('다른 접두사 이벤트는 외부 이벤트로 식별', () {
        // Given: 다른 접두사를 가진 Event
        final extEvent = (
          id: 'ext-99',
          title: 'Group Event',
          start: (day: 0, slot: 0),
          end: (day: 0, slot: 4),
          startTime: null,
          endTime: null,
          color: null,
        );

        // When/Then
        expect(PersonalScheduleAdapter.isPersonalScheduleEvent(extEvent),
            false);
      });
    });

    group('Round-trip 변환 - 데이터 무결성', () {
      test('toEvent → fromEvent 변환 후에도 모든 정보 보존', () {
        // Given: 완전한 개인 일정 정보
        final originalSchedule = PersonalSchedule(
          id: 123,
          title: 'Important Meeting',
          dayOfWeek: DayOfWeek.thursday,
          startTime: const TimeOfDay(hour: 13, minute: 30),
          endTime: const TimeOfDay(hour: 15, minute: 0),
          location: 'Conference Room',
          color: kPersonalScheduleColors[3],
        );

        // When: 양방향 변환
        final event =
            PersonalScheduleAdapter.toEvent(originalSchedule, weekStart);
        final request = PersonalScheduleAdapter.fromEvent(
          event,
          weekStart,
          location: originalSchedule.location,
          color: originalSchedule.color,
        );

        // Then: 모든 데이터 동일성 검증
        expect(request.title, originalSchedule.title);
        expect(request.dayOfWeek, originalSchedule.dayOfWeek);
        expect(request.startTime, originalSchedule.startTime);
        expect(request.endTime, originalSchedule.endTime);
        expect(request.location, originalSchedule.location);
        expect(request.color, originalSchedule.color);
      });
    });
  });
}
