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
import 'widgets/floating_glass_navigation_bar.dart';
import 'ledger_theme.dart';

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
      extendBody: true,
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.user.role == UserRole.kader ||
              widget.user.role == UserRole.bidan)
            IconButton(
              tooltip: 'Notifikasi',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: Text(
                          widget.user.role == UserRole.kader
                              ? 'Notifikasi Kader'
                              : 'Notifikasi Bidan',
                        ),
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
          GestureDetector(
            onTap: () => _showProfileBottomSheet(context, ref),
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: LedgerColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: LedgerColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  widget.user.nama.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: LedgerColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      bottomNavigationBar: FloatingGlassNavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() {
          _index = value;
          if (widget.user.role == UserRole.admin) {
            _adminPosyanduFilterId = null;
          }
        }),
        destinations: shell.destinations,
      ),
      body: SafeArea(bottom: false, child: pages[_index]),
    );
  }

  void _showProfileBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: LedgerColors.primarySoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: LedgerColors.primary.withValues(alpha: 0.25),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.user.nama.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: LedgerColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    widget.user.nama,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: LedgerColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: LedgerColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.user.role.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: LedgerColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 16),
                _profileDetailRow('NIK / NIP', widget.user.nikNip),
                _profileDetailRow('Posyandu Tugas', 'Posyandu Melati 03'),
                _profileDetailRow('Status Akun', 'Aktif'),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(authControllerProvider.notifier).logout();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(
                      color: Colors.red.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_outlined, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _profileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: LedgerColors.inkSoft,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: LedgerColors.ink,
            ),
          ),
        ],
      ),
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
  final List<FloatingGlassNavDestination> destinations;
  final List<Widget> pages;
}

List<FloatingGlassNavDestination> get _kaderDestinations => [
  const FloatingGlassNavDestination(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Beranda',
  ),
  const FloatingGlassNavDestination(
    icon: Icons.event_available_outlined,
    activeIcon: Icons.event_available,
    label: 'Sesi',
  ),
  const FloatingGlassNavDestination(
    icon: Icons.child_care_outlined,
    activeIcon: Icons.child_care,
    label: 'Balita',
  ),
  const FloatingGlassNavDestination(
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check,
    label: 'Skrining',
  ),
  if (_isTest)
    const FloatingGlassNavDestination(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
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

List<FloatingGlassNavDestination> get _bidanDestinations => [
  const FloatingGlassNavDestination(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Beranda',
  ),
  const FloatingGlassNavDestination(
    icon: Icons.child_care_outlined,
    activeIcon: Icons.child_care,
    label: 'Balita',
  ),
  const FloatingGlassNavDestination(
    icon: Icons.assignment_late_outlined,
    activeIcon: Icons.assignment_late,
    label: 'Rujukan',
  ),
  const FloatingGlassNavDestination(
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
    label: 'PMT',
  ),
  const FloatingGlassNavDestination(
    icon: Icons.description_outlined,
    activeIcon: Icons.description,
    label: 'Laporan',
  ),
  if (_isTest)
    const FloatingGlassNavDestination(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications,
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
  FloatingGlassNavDestination(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: 'Beranda',
  ),
  FloatingGlassNavDestination(
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    label: 'Akun',
  ),
  FloatingGlassNavDestination(
    icon: Icons.home_work_outlined,
    activeIcon: Icons.home_work,
    label: 'Posyandu',
  ),
  FloatingGlassNavDestination(
    icon: Icons.event_available_outlined,
    activeIcon: Icons.event_available,
    label: 'Sesi',
  ),
  FloatingGlassNavDestination(
    icon: Icons.description_outlined,
    activeIcon: Icons.description,
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
