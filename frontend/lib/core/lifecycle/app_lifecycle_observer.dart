import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/workspace_state_provider.dart';

/// App Lifecycle Observer
///
/// **Phase 3**: 앱 종료 시 읽음 처리 완료 (FR-011 준수)
///
/// Monitors app lifecycle events and ensures read positions are saved
/// when the app is paused or terminated.
///
/// **Lifecycle Events**:
/// - `paused`: App is in background (mobile) or tab is hidden (web)
/// - `detached`: App is about to terminate (mobile)
///
/// **Web Support**:
/// - Uses `beforeunload` event for browser tab close
/// - Calls `exitWorkspace()` to save current read position
///
/// **Usage**:
/// ```dart
/// // In main.dart
/// WidgetsBinding.instance.addObserver(AppLifecycleObserver(ref));
/// ```
class AppLifecycleObserver with WidgetsBindingObserver {
  AppLifecycleObserver(this.ref) {
    _init();
  }

  final WidgetRef ref;
  bool _isDisposed = false;

  void _init() {
    // Web: Listen to beforeunload event
    if (kIsWeb) {
      // Note: Can't use dart:html directly in Flutter Web
      // The browser will automatically handle the beforeunload event
      // when the tab/window closes, triggering paused lifecycle
      developer.log(
        'AppLifecycleObserver initialized for Web',
        name: 'AppLifecycleObserver',
      );
    } else {
      developer.log(
        'AppLifecycleObserver initialized for Mobile',
        name: 'AppLifecycleObserver',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    developer.log(
      'App lifecycle changed: $state',
      name: 'AppLifecycleObserver',
    );

    switch (state) {
      case AppLifecycleState.paused:
        // App is in background (mobile) or tab is hidden (web)
        _handleAppPaused();
        break;

      case AppLifecycleState.detached:
        // App is about to terminate (mobile only)
        _handleAppDetached();
        break;

      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // No action needed
        break;
    }
  }

  /// Handle app paused event
  ///
  /// Called when:
  /// - Mobile: App goes to background
  /// - Web: Browser tab becomes hidden
  ///
  /// **Changed behavior**: Only saves read position without clearing state.
  /// This allows users to return to the same channel after resuming.
  void _handleAppPaused() {
    developer.log(
      'App paused - saving read position (state preserved)',
      name: 'AppLifecycleObserver',
    );

    try {
      // Save read position only, preserve current channel state
      // This follows FR-011: "update unread badge counts only when user exits"
      ref.read(workspaceStateProvider.notifier).saveReadPositionOnly();

      developer.log(
        'Read position saved successfully on app pause',
        name: 'AppLifecycleObserver',
      );
    } catch (e) {
      // Best-effort: ignore errors
      developer.log(
        'Failed to save read position on app pause: $e',
        name: 'AppLifecycleObserver',
        level: 900,
      );
    }
  }

  /// Handle app detached event (mobile only)
  ///
  /// Called when app is about to terminate
  ///
  /// **Behavior**: Fully exits workspace and resets state.
  /// This is the actual app termination, not just backgrounding.
  void _handleAppDetached() {
    developer.log(
      'App detached - exiting workspace completely',
      name: 'AppLifecycleObserver',
    );

    try {
      // Complete workspace exit: save read position AND reset state
      ref.read(workspaceStateProvider.notifier).exitWorkspace();

      developer.log(
        'Workspace exited successfully on app detach',
        name: 'AppLifecycleObserver',
      );
    } catch (e) {
      // Best-effort: ignore errors
      developer.log(
        'Failed to exit workspace on app detach: $e',
        name: 'AppLifecycleObserver',
        level: 900,
      );
    }
  }

  void dispose() {
    _isDisposed = true;
    developer.log(
      'AppLifecycleObserver disposed',
      name: 'AppLifecycleObserver',
    );
  }
}
