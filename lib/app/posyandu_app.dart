import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
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
    final shell = _shellSpec(widget.user.role);
    final title = shell.titles[_index];
    final pages = shell.pages;
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
        destinations: shell.destinations,
      ),
      body: SafeArea(child: pages[_index]),
    );
  }

  _RoleShellSpec _shellSpec(UserRole role) {
    return switch (role) {
      UserRole.admin => _RoleShellSpec(
        titles: _adminTitles,
        destinations: _adminDestinations,
        pages: [
          AdminDashboardPage(onNavigate: _navigateAdmin),
          AdminDashboardPage(focus: 'akun', onNavigate: _navigateAdmin),
          AdminDashboardPage(focus: 'posyandu', onNavigate: _navigateAdmin),
          AdminDashboardPage(focus: 'laporan', onNavigate: _navigateAdmin),
        ],
      ),
      UserRole.bidan => _RoleShellSpec(
        titles: _bidanTitles,
        destinations: _bidanDestinations,
        pages: [
          BidanDashboardPage(onNavigate: _navigateBidan),
          BidanDashboardPage(focus: 'rujukan', onNavigate: _navigateBidan),
          BidanDashboardPage(focus: 'pmt', onNavigate: _navigateBidan),
          BidanDashboardPage(focus: 'laporan', onNavigate: _navigateBidan),
          BidanDashboardPage(focus: 'notifikasi', onNavigate: _navigateBidan),
        ],
      ),
      UserRole.kader => _RoleShellSpec(
        titles: _kaderTitles,
        destinations: _kaderDestinations,
        pages: [
          KaderDashboardPage(onNavigate: _navigateKader),
          KaderDashboardPage(focus: 'sesi', onNavigate: _navigateKader),
          KaderDashboardPage(focus: 'balita', onNavigate: _navigateKader),
          KaderDashboardPage(focus: 'skrining', onNavigate: _navigateKader),
          KaderDashboardPage(focus: 'notifikasi', onNavigate: _navigateKader),
        ],
      ),
    };
  }

  void _navigateKader(String focus) {
    final next = switch (focus) {
      'sesi' => 1,
      'balita' => 2,
      'skrining' => 3,
      'notifikasi' => 4,
      _ => 0,
    };
    setState(() => _index = next);
  }

  void _navigateBidan(String focus) {
    final next = switch (focus) {
      'rujukan' => 1,
      'pmt' => 2,
      'laporan' => 3,
      'notifikasi' => 4,
      _ => 0,
    };
    setState(() => _index = next);
  }

  void _navigateAdmin(String focus) {
    final next = switch (focus) {
      'akun' => 1,
      'posyandu' => 2,
      'laporan' => 3,
      _ => 0,
    };
    setState(() => _index = next);
  }
}

class _RoleShellSpec {
  const _RoleShellSpec({
    required this.titles,
    required this.destinations,
    required this.pages,
  });

  final List<String> titles;
  final List<NavigationDestination> destinations;
  final List<Widget> pages;
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

const _adminDestinations = [
  NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Beranda'),
  NavigationDestination(icon: Icon(Icons.people_outline), label: 'Akun'),
  NavigationDestination(
    icon: Icon(Icons.home_work_outlined),
    label: 'Posyandu',
  ),
  NavigationDestination(
    icon: Icon(Icons.description_outlined),
    label: 'Laporan',
  ),
];

const _adminTitles = ['Beranda Admin', 'Akun', 'Posyandu', 'Laporan'];
