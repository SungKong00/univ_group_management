import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: App()));
}
