import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/bidan/presentation/pages/bidan_dashboard_page.dart';
import '../features/kader/presentation/pages/kader_dashboard_page.dart';
import '../shared/widgets/ledger_widgets.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_colors.dart';

bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

class PosyanduApp extends ConsumerWidget {
  const PosyanduApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return MaterialApp(
      title: 'Posyandu Desa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
  int? _adminPosyanduFilterId;

  @override
  Widget build(BuildContext context) {
    final shell = _shellSpec(widget.user.role);
    final title = shell.titles[_index];
    final pages = shell.pages;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.user.role == UserRole.kader || widget.user.role == UserRole.bidan)
            IconButton(
              tooltip: 'Notifikasi',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: Text(widget.user.role == UserRole.kader
                            ? 'Notifikasi Kader'
                            : 'Notifikasi Bidan'),
                        bottom: const PreferredSize(
                          preferredSize: Size.fromHeight(1),
                          child: Divider(height: 1, color: AppColors.divider),
                        ),
                      ),
                      body: SafeArea(
                        child: widget.user.role == UserRole.kader
                            ? KaderDashboardPage(
                                focus: 'notifikasi',
                                onNavigate: (focus) {
                                  Navigator.of(context).pop();
                                  _navigateKader(focus);
                                },
                              )
                            : BidanDashboardPage(
                                focus: 'notifikasi',
                                onNavigate: (focus) {
                                  Navigator.of(context).pop();
                                  _navigateBidan(focus);
                                },
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() {
          _index = value;
          if (widget.user.role == UserRole.admin) {
            _adminPosyanduFilterId = null;
          }
        }),
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
          AdminDashboardPage(
            focus: 'akun',
            selectedPosyanduId: _adminPosyanduFilterId,
            onNavigate: _navigateAdmin,
          ),
          AdminDashboardPage(focus: 'posyandu', onNavigate: _navigateAdmin),
          AdminDashboardPage(
            focus: 'sesi',
            selectedPosyanduId: _adminPosyanduFilterId,
            onNavigate: _navigateAdmin,
          ),
          AdminDashboardPage(focus: 'laporan', onNavigate: _navigateAdmin),
        ],
      ),
      UserRole.bidan => _RoleShellSpec(
        titles: _bidanTitles,
        destinations: _bidanDestinations,
        pages: [
          BidanDashboardPage(onNavigate: _navigateBidan),
          BidanDashboardPage(focus: 'balita', onNavigate: _navigateBidan),
          BidanDashboardPage(focus: 'rujukan', onNavigate: _navigateBidan),
          BidanDashboardPage(focus: 'pmt', onNavigate: _navigateBidan),
          BidanDashboardPage(focus: 'laporan', onNavigate: _navigateBidan),
          if (_isTest)
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
          if (_isTest)
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
      'notifikasi' => _isTest ? 4 : 0,
      _ => 0,
    };
    setState(() => _index = next);
  }

  void _navigateBidan(String focus) {
    final next = switch (focus) {
      'balita' => 1,
      'rujukan' => 2,
      'pmt' => 3,
      'laporan' => 4,
      'notifikasi' => _isTest ? 5 : 0,
      _ => 0,
    };
    setState(() => _index = next);
  }

  void _navigateAdmin(String focus) {
    final parts = focus.split(':');
    final target = parts.first;
    final filter = parts.length > 1 ? int.tryParse(parts[1]) : null;
    final next = switch (target) {
      'akun' => 1,
      'posyandu' => 2,
      'sesi' => 3,
      'laporan' => 4,
      _ => 0,
    };
    setState(() {
      _index = next;
      _adminPosyanduFilterId = filter;
    });
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

List<NavigationDestination> get _kaderDestinations => [
  const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
  const NavigationDestination(
    icon: Icon(Icons.event_available_outlined),
    label: 'Sesi',
  ),
  const NavigationDestination(icon: Icon(Icons.child_care_outlined), label: 'Balita'),
  const NavigationDestination(
    icon: Icon(Icons.fact_check_outlined),
    label: 'Skrining',
  ),
  if (_isTest)
    const NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      label: 'Notifikasi',
    ),
];

List<String> get _kaderTitles => [
  'Beranda Kader',
  'Sesi Posyandu',
  'Register Balita',
  'Skrining Hari Ini',
  if (_isTest) 'Notifikasi Kader',
];

List<NavigationDestination> get _bidanDestinations => [
  const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
  const NavigationDestination(icon: Icon(Icons.child_care_outlined), label: 'Balita'),
  const NavigationDestination(
    icon: Icon(Icons.assignment_late_outlined),
    label: 'Rujukan',
  ),
  const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'PMT'),
  const NavigationDestination(
    icon: Icon(Icons.description_outlined),
    label: 'Laporan',
  ),
  if (_isTest)
    const NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      label: 'Notifikasi',
    ),
];

List<String> get _bidanTitles => [
  'Beranda Bidan',
  'Data Balita',
  'Rujukan',
  'PMT',
  'Laporan',
  if (_isTest) 'Notifikasi Bidan',
];

const _adminDestinations = [
  NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Beranda'),
  NavigationDestination(icon: Icon(Icons.people_outline), label: 'Akun'),
  NavigationDestination(
    icon: Icon(Icons.home_work_outlined),
    label: 'Posyandu',
  ),
  NavigationDestination(
    icon: Icon(Icons.event_available_outlined),
    label: 'Sesi',
  ),
  NavigationDestination(
    icon: Icon(Icons.description_outlined),
    label: 'Laporan',
  ),
];

const _adminTitles = [
  'Beranda Admin',
  'Akun',
  'Posyandu',
  'Jadwal & Sesi',
  'Laporan',
];
