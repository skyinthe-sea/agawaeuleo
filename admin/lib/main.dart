import 'package:flutter/material.dart';

import 'admin_api.dart';
import 'config_store.dart';
import 'screens/config_screen.dart';
import 'screens/symptom_list_screen.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '아가왜울어 어드민',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B5B4A)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const AdminGate(),
    );
  }
}

/// 저장된 접속 설정이 있으면 목록으로, 없으면 설정 화면으로 분기한다.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final _store = ConfigStore();
  late Future<AdminConfig?> _future;

  @override
  void initState() {
    super.initState();
    _future = _store.load();
  }

  void _reload() => setState(() => _future = _store.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminConfig?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final config = snap.data;
        if (config == null || !config.isComplete) {
          return ConfigScreen(store: _store, onConnected: _reload);
        }
        return SymptomListScreen(
          api: AdminApi(url: config.url, serviceKey: config.serviceKey),
          onSignedOut: () async {
            await _store.clear();
            _reload();
          },
        );
      },
    );
  }
}
