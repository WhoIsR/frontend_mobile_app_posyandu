import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/token_store.dart';

void main() {
  runApp(PosyanduApp());
}

class PosyanduApp extends StatefulWidget {
  PosyanduApp({super.key, PosyanduApi? api, TokenStore? tokenStore})
    : api = api ?? HttpPosyanduApi(),
      tokenStore = tokenStore ?? SharedPreferencesTokenStore();

  final PosyanduApi api;
  final TokenStore tokenStore;

  static const paper = Color(0xFFF8F4EC);
  static const surface = Color(0xFFFFFDF8);
  static const line = Color(0xFFDDD2C3);
  static const ink = Color(0xFF25231F);
  static const inkSoft = Color(0xFF5D594F);
  static const primary = Color(0xFF4E6F5C);
  static const primarySoft = Color(0xFFDDE8DE);
  static const bidanBlue = Color(0xFF4F6F86);
  static const attention = Color(0xFF9A6A2F);
  static const attentionSoft = Color(0xFFF1E2C9);
  static const review = Color(0xFF9A4E3A);
  static const reviewSoft = Color(0xFFF0D8D1);

  @override
  State<PosyanduApp> createState() => _PosyanduAppState();
}

class _PosyanduAppState extends State<PosyanduApp> {
  AppUser? _user;
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await widget.tokenStore.read();
    if (token != null && widget.api is HttpPosyanduApi) {
      (widget.api as HttpPosyanduApi).token = token;
    }
    if (token == null) {
      setState(() => _booting = false);
      return;
    }
    try {
      final user = await widget.api.me();
      if (!mounted) return;
      setState(() {
        _user = user;
        _booting = false;
      });
    } catch (_) {
      await widget.tokenStore.clear();
      if (!mounted) return;
      setState(() => _booting = false);
    }
  }

  Future<void> _handleLogin(AuthSession session) async {
    await widget.tokenStore.write(session.token);
    if (!mounted) return;
    setState(() => _user = session.user);
  }

  Future<void> _logout() async {
    try {
      await widget.api.logout();
    } catch (_) {
      // Logout lokal tetap dilakukan agar kader/bidan tidak tertahan token lama.
    }
    await widget.tokenStore.clear();
    if (!mounted) return;
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posyandu Desa',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: _booting
          ? const _BootScreen()
          : _user == null
          ? LoginScreen(api: widget.api, onLoggedIn: _handleLogin)
          : RoleShell(api: widget.api, user: _user!, onLogout: _logout),
    );
  }

  ThemeData _theme() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: PosyanduApp.paper,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: PosyanduApp.primary,
            brightness: Brightness.light,
          ).copyWith(
            primary: PosyanduApp.primary,
            secondary: PosyanduApp.bidanBlue,
            surface: PosyanduApp.surface,
            outline: PosyanduApp.line,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PosyanduApp.surface,
        foregroundColor: PosyanduApp.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: PosyanduApp.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: PosyanduApp.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PosyanduApp.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PosyanduApp.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PosyanduApp.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: PosyanduApp.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api, required this.onLoggedIn});

  final PosyanduApi api;
  final ValueChanged<AuthSession> onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await widget.api.login(
        _nikController.text.trim(),
        _passwordController.text,
      );
      widget.onLoggedIn(session);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Koneksi ke server belum berhasil. Coba lagi sebentar.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 36),
            Text(
              'Posyandu Desa',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: PosyanduApp.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catatan tumbuh kembang dan tindak lanjut balita.',
              style: TextStyle(color: PosyanduApp.inkSoft, height: 1.4),
            ),
            const SizedBox(height: 32),
            TextField(
              key: const Key('nikField'),
              controller: _nikController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'NIK / NIP'),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('passwordField'),
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _InlineMessage(text: _error!, isError: true),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Memeriksa...' : 'Masuk'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Butuh bantuan akun? Hubungi bidan atau kader koordinator.',
              style: TextStyle(color: PosyanduApp.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class RoleShell extends StatefulWidget {
  const RoleShell({
    super.key,
    required this.api,
    required this.user,
    required this.onLogout,
  });

  final PosyanduApi api;
  final AppUser user;
  final VoidCallback onLogout;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isKader = widget.user.role == UserRole.kader;
    final pages = isKader
        ? [
            KaderDashboard(api: widget.api, user: widget.user),
            KaderDashboard(api: widget.api, user: widget.user, focus: 'sesi'),
            KaderDashboard(api: widget.api, user: widget.user, focus: 'balita'),
            KaderDashboard(api: widget.api, user: widget.user, focus: 'skrining'),
            KaderDashboard(api: widget.api, user: widget.user, focus: 'notifikasi'),
          ]
        : [
            BidanDashboard(api: widget.api, user: widget.user),
            BidanDashboard(api: widget.api, user: widget.user, focus: 'rujukan'),
            BidanDashboard(api: widget.api, user: widget.user, focus: 'pmt'),
            BidanDashboard(api: widget.api, user: widget.user, focus: 'laporan'),
            BidanDashboard(api: widget.api, user: widget.user, focus: 'notifikasi'),
          ];
    return Scaffold(
      appBar: AppBar(
        title: Text(isKader ? 'Beranda Kader' : 'Beranda Bidan'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: PosyanduApp.line),
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
  NavigationDestination(icon: Icon(Icons.event_available_outlined), label: 'Sesi'),
  NavigationDestination(icon: Icon(Icons.child_care_outlined), label: 'Balita'),
  NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Skrining'),
  NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Notifikasi'),
];

const _bidanDestinations = [
  NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
  NavigationDestination(icon: Icon(Icons.assignment_late_outlined), label: 'Rujukan'),
  NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'PMT'),
  NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Laporan'),
  NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Notifikasi'),
];

class KaderDashboard extends StatefulWidget {
  const KaderDashboard({
    super.key,
    required this.api,
    required this.user,
    this.focus,
  });

  final PosyanduApi api;
  final AppUser user;
  final String? focus;

  @override
  State<KaderDashboard> createState() => _KaderDashboardState();
}

class _KaderDashboardState extends State<KaderDashboard> {
  final _searchController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  Map<String, dynamic>? _session;
  List<Map<String, dynamic>> _children = [];
  List<Map<String, dynamic>> _screening = [];
  List<Map<String, dynamic>> _notifications = [];
  Map<String, dynamic>? _lastMeasurement;
  bool _loading = true;
  bool _saving = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = await widget.api.getActiveSession();
      final children = await widget.api.getChildren();
      final notifications = await widget.api.getNotifications();
      final screening = session == null
          ? const <Map<String, dynamic>>[]
          : (await widget.api.getScreening(_id(session))).data;
      if (!mounted) return;
      setState(() {
        _session = session;
        _children = children.data;
        _screening = screening;
        _notifications = notifications.data;
        _loading = false;
      });
    } catch (error) {
      _showMessage(_errorText(error), isError: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _search() async {
    try {
      final result = await widget.api.getChildren(search: _searchController.text);
      if (!mounted) return;
      setState(() => _children = result.data);
    } catch (error) {
      _showMessage(_errorText(error), isError: true);
    }
  }

  Future<void> _saveMeasurement() async {
    if (_session == null || _children.isEmpty) {
      _showMessage('Sesi aktif atau data balita belum tersedia.', isError: true);
      return;
    }
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));
    if (weight == null || height == null) {
      _showMessage('Isi berat badan dan tinggi badan dengan angka.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await widget.api.storeMeasurement(
        sessionId: _id(_session!),
        childId: _id(_children.first),
        weight: weight,
        height: height,
      );
      final screening = (await widget.api.getScreening(_id(_session!))).data;
      if (!mounted) return;
      setState(() {
        _lastMeasurement = saved;
        _screening = screening;
      });
      final failed = saved['status_prediksi'] == 'gagal';
      _showMessage(
        failed
            ? 'Pengukuran tersimpan. Prediksi dapat dicoba ulang saat koneksi stabil.'
            : 'Pengukuran tersimpan. Hasil skrining diperbarui.',
        isError: failed,
      );
    } catch (error) {
      _showMessage(_errorText(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _retryPrediction() async {
    final measurementId = _lastMeasurement == null ? null : _id(_lastMeasurement!);
    if (measurementId == null) return;
    try {
      final saved = await widget.api.retryPrediction(measurementId);
      final screening = _session == null
          ? const <Map<String, dynamic>>[]
          : (await widget.api.getScreening(_id(_session!))).data;
      if (!mounted) return;
      setState(() {
        _lastMeasurement = saved;
        _screening = screening;
      });
      _showMessage('Prediksi berhasil dicoba ulang.');
    } catch (error) {
      _showMessage(_errorText(error), isError: true);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _messageIsError = isError;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _LoadingList();
    }
    final child = _children.isEmpty ? null : _children.first;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        key: const Key('kaderList'),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Selamat datang, ${widget.user.nama}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text('Posyandu aktif hari ini', style: TextStyle(color: PosyanduApp.inkSoft)),
          const SizedBox(height: 16),
          StatusPanel(
            title: 'Sesi hari ini',
            subtitle: _session == null
                ? 'Belum ada sesi berjalan untuk Posyandu ini.'
                : 'Sesi ${_dateText(_session!['tanggal'])} | Status ${_session!['status'] ?? '-'}',
            accent: PosyanduApp.primary,
            child: Text(widget.focus == 'sesi' ? 'Tarik ke bawah untuk memuat ulang sesi.' : 'Input Pengukuran'),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Cari balita'),
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: 'Cari nama balita, ibu, atau NIK',
              suffixIcon: IconButton(
                tooltip: 'Cari',
                onPressed: _search,
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_children.isEmpty)
            const EmptyState(text: 'Belum ada balita pada hasil pencarian.')
          else
            ..._children.take(3).map((row) => ChildRow(row: row)),
          const SizedBox(height: 16),
          const SectionTitle('Input pengukuran'),
          MeasurementPanel(
            child: child,
            weightController: _weightController,
            heightController: _heightController,
            saving: _saving,
            onSave: _saveMeasurement,
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _InlineMessage(text: _message!, isError: _messageIsError),
          ],
          if (_lastMeasurement?['status_prediksi'] == 'gagal') ...[
            const SizedBox(height: 8),
            const StatusBadge(
              label: 'Prediksi gagal',
              color: PosyanduApp.inkSoft,
              softColor: PosyanduApp.line,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _retryPrediction,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
          const SizedBox(height: 16),
          const SectionTitle('Hasil Skrining Hari Ini'),
          if (_screening.isEmpty)
            const EmptyState(text: 'Belum ada hasil skrining pada sesi ini.')
          else
            ..._screening.map((row) => ScreeningRow(row: row)),
          const SizedBox(height: 16),
          const SectionTitle('Notifikasi'),
          if (_notifications.isEmpty)
            const EmptyState(text: 'Belum ada notifikasi.')
          else
            ..._notifications.take(3).map((row) => NotificationRow(row: row)),
        ],
      ),
    );
  }
}

class BidanDashboard extends StatefulWidget {
  const BidanDashboard({
    super.key,
    required this.api,
    required this.user,
    this.focus,
  });

  final PosyanduApi api;
  final AppUser user;
  final String? focus;

  @override
  State<BidanDashboard> createState() => _BidanDashboardState();
}

class _BidanDashboardState extends State<BidanDashboard> {
  final _noteController = TextEditingController(text: 'Observasi dan pantau ulang.');
  List<Map<String, dynamic>> _referrals = [];
  List<Map<String, dynamic>> _pmt = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  bool _savingValidation = false;
  String _decision = 'observasi';
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final referrals = await widget.api.getReferrals();
      final pmt = await widget.api.getPmt();
      final notifications = await widget.api.getNotifications();
      if (!mounted) return;
      setState(() {
        _referrals = referrals.data;
        _pmt = pmt.data;
        _notifications = notifications.data;
        _loading = false;
      });
    } catch (error) {
      _showMessage(_errorText(error), isError: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _validateReferral() async {
    if (_referrals.isEmpty) {
      _showMessage('Belum ada rujukan untuk divalidasi.', isError: true);
      return;
    }
    setState(() => _savingValidation = true);
    try {
      await widget.api.validateReferral(
        referralId: _id(_referrals.first),
        decision: _decision,
        note: _noteController.text.trim().isEmpty
            ? 'Observasi dan pantau ulang.'
            : _noteController.text.trim(),
      );
      _showMessage('Validasi tersimpan');
      await _load();
    } catch (error) {
      _showMessage(_errorText(error), isError: true);
    } finally {
      if (mounted) setState(() => _savingValidation = false);
    }
  }

  Future<void> _downloadReport(String type) async {
    try {
      final bytes = await widget.api.downloadReport(type: type);
      _showMessage('PDF berhasil diminta (${bytes.lengthInBytes} byte).');
    } catch (error) {
      _showMessage(_errorText(error), isError: true);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _messageIsError = isError;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _LoadingList();
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Rujukan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_referrals.isEmpty)
            const EmptyState(text: 'Belum ada rujukan masuk.')
          else
            ..._referrals.take(4).map((row) => ReferralRow(row: row)),
          const SizedBox(height: 16),
          const SectionTitle('Validasi Medis'),
          StatusPanel(
            title: 'Keputusan',
            subtitle: 'Observasi, konseling, PMT, rujuk puskesmas, atau cek ulang data.',
            accent: PosyanduApp.bidanBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _decision,
                  decoration: const InputDecoration(labelText: 'Keputusan'),
                  items: const [
                    DropdownMenuItem(value: 'observasi', child: Text('Observasi')),
                    DropdownMenuItem(value: 'konseling', child: Text('Konseling')),
                    DropdownMenuItem(value: 'pmt', child: Text('PMT')),
                    DropdownMenuItem(value: 'rujuk_puskesmas', child: Text('Rujuk Puskesmas')),
                    DropdownMenuItem(value: 'cek_ulang_data', child: Text('Cek ulang data')),
                  ],
                  onChanged: (value) => setState(() => _decision = value ?? 'observasi'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Catatan bidan'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('validateButton'),
                  onPressed: _savingValidation ? null : _validateReferral,
                  child: Text(_savingValidation ? 'Menyimpan...' : 'Simpan Validasi'),
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _InlineMessage(text: _message!, isError: _messageIsError),
          ],
          const SizedBox(height: 16),
          const SectionTitle('PMT'),
          if (_pmt.isEmpty)
            const EmptyState(text: 'Belum ada stok PMT.')
          else
            ..._pmt.map((row) => StockRow(row: row)),
          const SizedBox(height: 16),
          const SectionTitle('Laporan PDF'),
          ReportPicker(onDownload: _downloadReport),
          const SizedBox(height: 16),
          const SectionTitle('Notifikasi'),
          if (_notifications.isEmpty)
            const EmptyState(text: 'Belum ada notifikasi.')
          else
            ..._notifications.take(3).map((row) => NotificationRow(row: row)),
        ],
      ),
    );
  }
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: PosyanduApp.inkSoft,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeasurementPanel extends StatelessWidget {
  const MeasurementPanel({
    super.key,
    required this.child,
    required this.weightController,
    required this.heightController,
    required this.saving,
    required this.onSave,
  });

  final Map<String, dynamic>? child;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              child == null
                  ? 'Pilih balita dari hasil pencarian.'
                  : '${child!['nama_balita']}\nIbu: ${child!['nama_ibu'] ?? '-'}',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('weightField'),
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Berat badan (kg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('heightField'),
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tinggi badan (cm)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('saveMeasurementButton'),
              onPressed: saving ? null : onSave,
              child: Text(saving ? 'Menyimpan...' : 'Simpan & Lanjut'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChildRow extends StatelessWidget {
  const ChildRow({super.key, required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    return _ListTileFrame(
      title: row['nama_balita']?.toString() ?? '-',
      subtitle: 'Ibu: ${row['nama_ibu'] ?? '-'}',
      trailing: const StatusBadge(
        label: 'Input',
        color: PosyanduApp.primary,
        softColor: PosyanduApp.primarySoft,
      ),
    );
  }
}

class ScreeningRow extends StatelessWidget {
  const ScreeningRow({super.key, required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final failed = row['status_prediksi'] == 'gagal';
    final risk = row['risk_level']?.toString();
    final label = failed ? 'Prediksi gagal' : riskLabel(risk);
    final colors = badgeColors(failed ? 'gagal' : risk);
    return _ListTileFrame(
      title: row['nama_balita']?.toString() ?? '-',
      subtitle: failed
          ? 'Pengukuran tersimpan. Prediksi dapat dicoba ulang saat koneksi stabil.'
          : riskMessage(risk),
      trailing: StatusBadge(
        label: label,
        color: colors.$1,
        softColor: colors.$2,
      ),
    );
  }
}

class ReferralRow extends StatelessWidget {
  const ReferralRow({super.key, required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final risk = row['risk_level']?.toString();
    final colors = badgeColors(risk);
    return _ListTileFrame(
      title: row['nama_balita']?.toString() ?? '-',
      subtitle: 'Ibu: ${row['nama_ibu'] ?? '-'} | ${row['status_rujukan'] ?? '-'}',
      trailing: StatusBadge(
        label: riskLabel(risk),
        color: colors.$1,
        softColor: colors.$2,
      ),
    );
  }
}

class StockRow extends StatelessWidget {
  const StockRow({super.key, required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final stock = _idValue(row['stok_saat_ini']);
    final min = _idValue(row['stok_minimum']);
    final low = stock < min;
    return _ListTileFrame(
      title: row['nama_barang']?.toString() ?? '-',
      subtitle: 'Stok $stock ${row['satuan'] ?? ''} | Minimum $min',
      trailing: StatusBadge(
        label: low ? 'Stok menipis' : 'Aman',
        color: low ? PosyanduApp.attention : PosyanduApp.primary,
        softColor: low ? PosyanduApp.attentionSoft : PosyanduApp.primarySoft,
      ),
    );
  }
}

class NotificationRow extends StatelessWidget {
  const NotificationRow({super.key, required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    return _ListTileFrame(
      title: row['judul']?.toString() ?? 'Notifikasi',
      subtitle: row['pesan']?.toString() ?? '-',
      trailing: const Icon(Icons.notifications_none),
    );
  }
}

class ReportPicker extends StatelessWidget {
  const ReportPicker({super.key, required this.onDownload});

  final Future<void> Function(String type) onDownload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prediksi Risiko'),
            const Text('Kehadiran Posyandu'),
            const Text('Distribusi PMT'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => onDownload('prediksi'),
              child: const Text('Download PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTileFrame extends StatelessWidget {
  const _ListTileFrame({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: PosyanduApp.inkSoft)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(flex: 0, child: trailing),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.softColor,
  });

  final String label;
  final Color color;
  final Color softColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28, maxWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(color: PosyanduApp.inkSoft)),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.text, this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? PosyanduApp.reviewSoft : PosyanduApp.primarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? PosyanduApp.review : PosyanduApp.primary,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? PosyanduApp.review : PosyanduApp.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        StatusPanel(
          title: 'Memuat data',
          subtitle: 'Menghubungkan aplikasi dengan server Posyandu.',
          accent: PosyanduApp.primary,
          child: LinearProgressIndicator(),
        ),
      ],
    );
  }
}

String riskLabel(String? risk) {
  return switch (risk) {
    'rendah' => 'Risiko rendah',
    'sedang' => 'Perlu perhatian',
    'tinggi' => 'Perlu ditinjau bidan',
    _ => 'Menunggu hasil',
  };
}

String riskMessage(String? risk) {
  return switch (risk) {
    'rendah' => 'Pertumbuhan tercatat dalam risiko rendah.',
    'sedang' => 'Pertumbuhan anak perlu diperhatikan. Data akan ditinjau tenaga kesehatan.',
    'tinggi' => 'Data perlu ditinjau bidan. Ini skrining awal, bukan diagnosis.',
    _ => 'Pengukuran tersimpan. Prediksi diproses di belakang.',
  };
}

(Color, Color) badgeColors(String? risk) {
  return switch (risk) {
    'rendah' => (PosyanduApp.primary, PosyanduApp.primarySoft),
    'sedang' => (PosyanduApp.attention, PosyanduApp.attentionSoft),
    'tinggi' => (PosyanduApp.review, PosyanduApp.reviewSoft),
    'gagal' => (PosyanduApp.inkSoft, PosyanduApp.line),
    _ => (PosyanduApp.bidanBlue, PosyanduApp.primarySoft),
  };
}

String _errorText(Object error) {
  if (error is ApiException) return error.message;
  return 'Koneksi ke server belum berhasil. Coba lagi sebentar.';
}

int _id(Map<String, dynamic> row) => _idValue(row['id']);

int _idValue(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _dateText(Object? value) => value?.toString() ?? '-';
