import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/bidan/presentation/pages/bidan_dashboard_page.dart';
import '../features/kader/presentation/pages/kader_dashboard_page.dart';
import '../shared/widgets/ledger_widgets.dart';
import 'ledger_theme.dart';

class PosyanduApp extends ConsumerWidget {
  const PosyanduApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return MaterialApp(
      title: 'Posyandu Desa',
      debugShowCheckedModeBanner: false,
      theme: LedgerTheme.light(),
      home: auth.isBooting
          ? const _BootScreen()
          : auth.user == null
          ? const LoginPage()
          : RoleShell(user: auth.user!),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingPanel());
  }
}

class RoleShell extends ConsumerStatefulWidget {
  const RoleShell({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends ConsumerState<RoleShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isKader = widget.user.role == UserRole.kader;
    final title = isKader ? _kaderTitles[_index] : _bidanTitles[_index];
    final pages = isKader
        ? const [
            KaderDashboardPage(),
            KaderDashboardPage(focus: 'sesi'),
            KaderDashboardPage(focus: 'balita'),
            KaderDashboardPage(focus: 'skrining'),
            KaderDashboardPage(focus: 'notifikasi'),
          ]
        : const [
            BidanDashboardPage(),
            BidanDashboardPage(focus: 'rujukan'),
            BidanDashboardPage(focus: 'pmt'),
            BidanDashboardPage(focus: 'laporan'),
            BidanDashboardPage(focus: 'notifikasi'),
          ];
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: LedgerColors.line),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: isKader ? _kaderDestinations : _bidanDestinations,
      ),
      body: SafeArea(child: pages[_index]),
    );
  }
}

const _kaderDestinations = [
  NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
  NavigationDestination(
    icon: Icon(Icons.event_available_outlined),
    label: 'Sesi',
  ),
  NavigationDestination(icon: Icon(Icons.child_care_outlined), label: 'Balita'),
  NavigationDestination(
    icon: Icon(Icons.fact_check_outlined),
    label: 'Skrining',
  ),
  NavigationDestination(
    icon: Icon(Icons.notifications_outlined),
    label: 'Notifikasi',
  ),
];

const _kaderTitles = [
  'Beranda Kader',
  'Sesi Posyandu',
  'Register Balita',
  'Skrining Hari Ini',
  'Notifikasi Kader',
];

const _bidanDestinations = [
  NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
  NavigationDestination(
    icon: Icon(Icons.assignment_late_outlined),
    label: 'Rujukan',
  ),
  NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'PMT'),
  NavigationDestination(
    icon: Icon(Icons.description_outlined),
    label: 'Laporan',
  ),
  NavigationDestination(
    icon: Icon(Icons.notifications_outlined),
    label: 'Notifikasi',
  ),
];

const _bidanTitles = [
  'Beranda Bidan',
  'Rujukan',
  'PMT',
  'Laporan',
  'Notifikasi Bidan',
];
