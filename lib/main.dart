import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_design.dart';
import 'app_models.dart';

const _supabaseUrl = 'https://xcroireqjttpofihfnql.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhjcm9pcmVxanR0cG9maWhmbnFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAxNjAzODQsImV4cCI6MjA5NTczNjM4NH0.oqZ8J2BiT8A2tw3rvGfXOlF5ZaHY_EQk7S0dF5cridw';
const _adminEmail = 'kcprstlmch@gmail.com';
const _mobileRedirectUrl = 'io.doorka.app://login-callback';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseAnonKey,
  );

  runApp(const DoorkaApp());
}

SupabaseClient get _supabase => Supabase.instance.client;

final List<Map<String, dynamic>> _localLeadSessions = [];
final ValueNotifier<String?> _avatarPathNotifier = ValueNotifier<String?>(null);
final ValueNotifier<int> _defaultLeadGoalNotifier = ValueNotifier<int>(9);
const _avatarPathPreferenceKey = 'doorka.avatar_path';
const _defaultLeadGoalPreferenceKey = 'doorka.default_lead_goal';

class DoorkaApp extends StatelessWidget {
  const DoorkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Doorka',
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSubscription;
  Session? _session;
  bool _profileSyncing = true;

  @override
  void initState() {
    super.initState();
    _session = _supabase.auth.currentSession;
    _syncCurrentProfile();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      setState(() {
        _session = state.session;
        _profileSyncing = state.session != null;
      });
      _syncCurrentProfile();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _syncCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _profileSyncing = false);
      }
      return;
    }

    final email = user.email?.toLowerCase();
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final fullName = metadata['full_name'] ?? metadata['name'];
    final avatarUrl = metadata['avatar_url'] ?? metadata['picture'];

    await _supabase.from('profiles').upsert({
      'id': user.id,
      'email': email,
      'full_name': fullName,
      'avatar_path': avatarUrl,
      'role': email == _adminEmail ? 'admin' : 'agent',
    });

    if (mounted) {
      setState(() => _profileSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const AuthScreen();
    }

    if (_profileSyncing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const HomeScreen();
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await action();
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Nie udało się wykonać tej akcji. Spróbuj ponownie.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() {
    return _runAuthAction(() async {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : _mobileRedirectUrl,
      );
    });
  }

  Future<void> _signInWithEmail() {
    return _runAuthAction(() async {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    });
  }

  Future<void> _signUpWithEmail() {
    return _runAuthAction(() async {
      await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: kIsWeb ? null : _mobileRedirectUrl,
      );
      _showMessage('Sprawdź skrzynkę e-mail, aby dokończyć rejestrację.');
    });
  }

  Future<void> _resetPassword() {
    return _runAuthAction(() async {
      await _supabase.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: kIsWeb ? null : _mobileRedirectUrl,
      );
      _showMessage('Wysłaliśmy link do zmiany hasła.');
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/d2d-door-ka-logo.png', height: 72),
                  const SizedBox(height: 36),
                  _GoogleSignInButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'E-mail'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Hasło'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    child: const Text('Zaloguj'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _signUpWithEmail,
                    child: const Text('Utwórz konto'),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: const Text('Nie pamiętasz hasła?'),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          side: const BorderSide(color: Color(0xFFDADCE0)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _GoogleMark(),
            SizedBox(width: 12),
            Text('Kontynuuj z Google'),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.18;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect.deflate(strokeWidth / 2), -0.08, 1.38, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect.deflate(strokeWidth / 2), 1.30, 1.55, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect.deflate(strokeWidth / 2), 2.85, 1.25, false, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect.deflate(strokeWidth / 2), 4.10, 1.45, false, paint);

    paint.color = const Color(0xFF4285F4);
    final y = size.height * 0.52;
    canvas.drawLine(
      Offset(size.width * 0.52, y),
      Offset(size.width * 0.94, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _contactsRefresh = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedAvatarPath();
  }

  Future<void> _loadSavedAvatarPath() async {
    final preferences = await SharedPreferences.getInstance();
    _avatarPathNotifier.value = preferences.getString(_avatarPathPreferenceKey);
    _defaultLeadGoalNotifier.value =
        preferences.getInt(_defaultLeadGoalPreferenceKey) ?? 9;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardPage(),
      ContactsPage(refreshSignal: _contactsRefresh),
      ClientsPage(onContactRestored: () => setState(() => _contactsRefresh++)),
      const StatisticsPage(),
      const AccountPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Image.asset('assets/images/app-sidebar-logo.png', height: 34),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE4E0D7)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              tooltip: 'Powiadomienia',
              onPressed: () {},
              icon: const Badge(
                smallSize: 8,
                backgroundColor: Color(0xFFE53935),
                child: Icon(Icons.notifications_none, size: 25),
              ),
            ),
          ),
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _items = [
    _BottomNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Dashboard',
    ),
    _BottomNavItem(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      label: 'Kontakty',
    ),
    _BottomNavItem(
      icon: Icons.precision_manufacturing_outlined,
      selectedIcon: Icons.precision_manufacturing,
      label: 'W realizacji',
    ),
    _BottomNavItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: 'Statystyka',
    ),
    _BottomNavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Konto',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1, thickness: 1, color: Color(0xFFE4E0D7)),
            Padding(
              padding: EdgeInsets.fromLTRB(6, 6, 6, bottomInset > 0 ? 2 : 6),
              child: Row(
                children: [
                  for (var index = 0; index < _items.length; index++) ...[
                    Expanded(
                      child: _BottomNavButton(
                        item: _items[index],
                        selected: currentIndex == index,
                        onTap: () => onDestinationSelected(index),
                      ),
                    ),
                    if (index != _items.length - 1)
                      Container(
                        width: 1,
                        height: 34,
                        color: const Color(0xFFE4E0D7),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _BottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? appTextPrimary : appTextSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.label == 'Konto')
              _BottomAccountInitials(selected: selected)
            else
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 22,
                color: color,
              ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAccountInitials extends StatelessWidget {
  const _BottomAccountInitials({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    return ValueListenableBuilder<String?>(
      valueListenable: _avatarPathNotifier,
      builder: (context, avatarPath, _) {
        return Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE7EFE8) : const Color(0xFFF2F0EA),
            shape: BoxShape.circle,
            border: Border.all(color: selected ? appBrand : appBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: avatarPath == null || avatarPath.isEmpty
              ? Text(
                  _userInitials(user),
                  style: TextStyle(
                    color: selected ? appBrand : appTextSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : _AvatarImage(path: avatarPath),
        );
      },
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.file(
      File(path),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

class ContactStatus {
  const ContactStatus(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;
}

const _contactStatuses = [
  ContactStatus('scheduled_meeting', 'Umówione spotkanie', Color(0xFF2F5D50)),
  ContactStatus('meeting_active', 'Spotkanie trwa', Color(0xFF0F766E)),
  ContactStatus('meeting_done', 'Spotkanie odbyte', Color(0xFF2374AB)),
  ContactStatus('signed_contract', 'Spisana umowa', Color(0xFF1E8E3E)),
  ContactStatus('interested', 'Zainteresowany', Color(0xFF5B7CFA)),
  ContactStatus('contact', 'Kontakt', Color(0xFF6D6A75)),
  ContactStatus('postponed', 'Przełożone', Color(0xFFB7791F)),
  ContactStatus('not_interested', 'Niezainteresowany', Color(0xFFD64545)),
  ContactStatus('no_contact', 'Brak kontaktu', Color(0xFF8A8F98)),
];

const _qualities = ['S', 'M', 'L', 'XL'];

bool _isMeetingStatus(String status) {
  return status == 'scheduled_meeting' ||
      status == 'meeting_active' ||
      status == 'meeting_done' ||
      status == 'signed_contract' ||
      status == 'postponed';
}

const _notInterestedReasons = [
  'Cena',
  'Musi przemyśleć',
  'Brak osoby decyzyjnej',
  'Nie teraz',
  'Beton',
  'Inne',
];

ContactStatus _statusByValue(String value) {
  return _contactStatuses.firstWhere(
    (status) => status.value == value,
    orElse: () => _contactStatuses.first,
  );
}

String _dateOnly(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _timeOnly(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay _timeOfDayFromText(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return const TimeOfDay(hour: 18, minute: 0);
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 18,
    minute: int.tryParse(parts[1]) ?? 0,
  );
}

String _shortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month';
}

String _weekdayName(DateTime date) {
  return const [
    'pon.',
    'wt.',
    'śr.',
    'czw.',
    'pt.',
    'sob.',
    'nd.',
  ][date.weekday - 1];
}

String _weekdayNameFull(DateTime date) {
  return const [
    'Poniedziałek',
    'Wtorek',
    'Środa',
    'Czwartek',
    'Piątek',
    'Sobota',
    'Niedziela',
  ][date.weekday - 1];
}

String _displayDateTime(DateTime date, String time) {
  final shortTime = time.length >= 5 ? time.substring(0, 5) : time;
  return '${_shortDate(date)} (${_weekdayName(date)}), $shortTime';
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  final letters = parts
      .take(2)
      .map((part) => part.characters.first.toUpperCase());
  final result = letters.join();
  return result.isEmpty ? '?' : result;
}

String _userDisplayName(User? user) {
  final metadata = user?.userMetadata ?? <String, dynamic>{};
  final name =
      (metadata['full_name'] ?? metadata['name'] ?? metadata['display_name'])
          ?.toString()
          .trim();
  if (name != null && name.isNotEmpty) return name;

  final email = user?.email ?? '';
  final localPart = email.split('@').first;
  if (localPart.isEmpty) return 'Agent';

  return localPart.replaceAll(RegExp(r'[._-]+'), ' ');
}

String _userInitials(User? user) {
  final displayName = _userDisplayName(user);
  final initials = _initials(displayName);
  if (initials != '?') return initials;

  final email = user?.email ?? '';
  return email.isEmpty ? 'A' : email.characters.first.toUpperCase();
}

Future<void> _callPhone(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: _normalizePhone(phone));
  final launched = await launchUrl(uri);
  if (launched || !context.mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('Nie udało się wykonać połączenia.')),
    );
}

String _normalizePhone(String phone) {
  return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
}

Future<void> _openMap(BuildContext context, String address) async {
  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': address,
  });
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (launched || !context.mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('Nie udało się otworzyć mapy.')),
    );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardData {
  const _DashboardData({
    required this.contacts,
    required this.clients,
    required this.leadSessions,
  });

  final List<Contact> contacts;
  final List<Client> clients;
  final List<Map<String, dynamic>> leadSessions;
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<_DashboardData> _dashboardFuture;
  bool _isLeadDayStarted = false;
  bool _isLeadDayPaused = false;
  bool _areTomorrowMeetingsCollapsed = false;
  bool _isWeeklyTileExpanded = true;
  int _sessionCollectedContacts = 0;
  Duration _leadDayElapsed = Duration.zero;
  Timer? _leadDayTimer;
  Timer? _leadDayBreakTimer;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboardData();
  }

  @override
  void dispose() {
    _leadDayTimer?.cancel();
    _leadDayBreakTimer?.cancel();
    super.dispose();
  }

  Future<_DashboardData> _fetchDashboardData() async {
    final results = await Future.wait([
      _supabase
          .from('contacts')
          .select()
          .isFilter('archived_at', null)
          .isFilter('moved_to_client_at', null),
      _supabase.from('clients').select().isFilter('archived_at', null),
      _fetchLeadSessionsForDashboard(),
    ]);

    final contacts = results[0]
        .map((item) => Contact.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    final clients = results[1]
        .map((item) => Client.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return _DashboardData(
      contacts: contacts,
      clients: clients,
      leadSessions: results[2]
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }

  Future<List<dynamic>> _fetchLeadSessionsForDashboard() async {
    try {
      final remoteSessions = await _supabase.from('lead_sessions').select();
      return [...remoteSessions, ..._localLeadSessions];
    } catch (_) {
      return List<Map<String, dynamic>>.from(_localLeadSessions);
    }
  }

  void _reload() {
    setState(() => _dashboardFuture = _fetchDashboardData());
  }

  void _startLeadDay() {
    _leadDayTimer?.cancel();
    _leadDayBreakTimer?.cancel();
    setState(() {
      _isLeadDayStarted = true;
      _isLeadDayPaused = false;
      _leadDayElapsed = Duration.zero;
      _sessionCollectedContacts = 0;
    });
    _leadDayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isLeadDayPaused) return;
      setState(() => _leadDayElapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _openLeadContactForm(String status) async {
    final saved = await showAddContactSheet(context, initialStatus: status);
    if (!mounted || saved != true) return;

    setState(() {
      _dashboardFuture = _fetchDashboardData();
      if (status == 'contact') {
        _sessionCollectedContacts++;
      }
    });
  }

  Future<void> _deleteDashboardContact(Contact contact) async {
    await _supabase.from('contacts').delete().eq('id', contact.id);
    _reload();
  }

  Future<void> _editDashboardMeetingTime(Contact contact) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDayFromText(contact.contactTime),
    );
    if (picked == null) return;

    await _supabase
        .from('contacts')
        .update({
          'contact_time': _timeOnly(picked),
          'meeting_time': _timeOnly(picked),
        })
        .eq('id', contact.id);

    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FutureBuilder<_DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              text: 'Nie udało się pobrać danych startowych.',
              detail: snapshot.error.toString(),
            );
          }

          final data =
              snapshot.data ??
              const _DashboardData(contacts: [], clients: [], leadSessions: []);
          final today = DateTime.now();
          final scheduledMeetings =
              data.contacts.where((contact) {
                return _isMeetingStatus(contact.status) &&
                    contact.status != 'signed_contract';
              }).toList()..sort((a, b) {
                final aDate = a.contactDate ?? DateTime(9999);
                final bDate = b.contactDate ?? DateTime(9999);
                final dateCompare = aDate.compareTo(bDate);
                if (dateCompare != 0) return dateCompare;
                return a.contactTime.compareTo(b.contactTime);
              });
          final overdueMeetings = data.contacts.where((contact) {
            if (contact.status != 'scheduled_meeting' ||
                contact.contactDate == null) {
              return false;
            }
            final contactDay = DateTime(
              contact.contactDate!.year,
              contact.contactDate!.month,
              contact.contactDate!.day,
            );
            final todayOnly = DateTime(today.year, today.month, today.day);
            return contactDay.isBefore(todayOnly);
          }).toList();
          final collectedContacts = data.contacts
              .where((contact) => !_isMeetingStatus(contact.status))
              .toList();

          final visibleCollectedContacts = _areTomorrowMeetingsCollapsed
              ? <Contact>[]
              : collectedContacts;
          final weeklyStats = _buildWeeklyDashboardStats(data);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _defaultLeadGoalNotifier,
                  builder: (context, dailyGoal, _) {
                    return _ActiveDashboardTile(
                      today: DateTime.now(),
                      dailyGoal: dailyGoal,
                      isStarted: _isLeadDayStarted,
                      isPaused: _isLeadDayPaused,
                      elapsed: _leadDayElapsed,
                      currentMeetings: scheduledMeetings.length,
                      currentContacts: _sessionCollectedContacts,
                      onStart: _startLeadDay,
                      onScheduleMeeting: () =>
                          _openLeadContactForm('scheduled_meeting'),
                      onAddLead: () => _openLeadContactForm('contact'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _DashboardBodyPadding(
                  child: _DashboardList(
                    title: 'Umówione spotkania',
                    headerTrailing:
                        scheduledMeetings.isEmpty ||
                            scheduledMeetings.first.contactDate == null
                        ? null
                        : '${_shortDate(scheduledMeetings.first.contactDate!)} | ${_weekdayNameFull(scheduledMeetings.first.contactDate!)}',
                    emptyText: 'Brak umówionych spotkań.',
                    contacts: scheduledMeetings,
                    leadingIcon: Icons.handshake_outlined,
                    onDelete: _deleteDashboardContact,
                    onEditMeetingTime: _editDashboardMeetingTime,
                  ),
                ),
                if (overdueMeetings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DashboardBodyPadding(
                    child: _DashboardList(
                      title: 'Zaległe / wymaga akcji',
                      emptyText: 'Brak zaległych spotkań.',
                      contacts: overdueMeetings,
                      leadingIcon: Icons.priority_high_outlined,
                      accentColor: appDanger,
                      onDelete: _deleteDashboardContact,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _DashboardBodyPadding(
                  child: _DashboardList(
                    title: 'Zebrane kontakty',
                    emptyText: 'Tutaj pojawią się zebrane leady',
                    contacts: visibleCollectedContacts,
                    leadingIcon: Icons.event_available_outlined,
                    onDelete: _deleteDashboardContact,
                    showExpandAction: true,
                    isExpanded: !_areTomorrowMeetingsCollapsed,
                    onToggleExpanded: () => setState(
                      () => _areTomorrowMeetingsCollapsed =
                          !_areTomorrowMeetingsCollapsed,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _DashboardBodyPadding(
                  child: _WeeklyDashboardTile(
                    stats: weeklyStats,
                    isExpanded: _isWeeklyTileExpanded,
                    onToggleExpanded: () => setState(
                      () => _isWeeklyTileExpanded = !_isWeeklyTileExpanded,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  _WeekDashboardStats _buildWeeklyDashboardStats(_DashboardData data) {
    final now = DateTime.now();
    final thisWeekStart = _weekStart(now);
    final previousWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final nextWeekStart = thisWeekStart.add(const Duration(days: 7));

    final thisMeetings = data.contacts
        .where(
          (contact) => _isDashboardMeetingInPeriod(
            contact,
            thisWeekStart,
            nextWeekStart,
          ),
        )
        .length;
    final previousMeetings = data.contacts
        .where(
          (contact) => _isDashboardMeetingInPeriod(
            contact,
            previousWeekStart,
            thisWeekStart,
          ),
        )
        .length;

    final thisClients = data.clients
        .where(
          (client) => _isDateInPeriod(
            client.contractSignedAt,
            thisWeekStart,
            nextWeekStart,
          ),
        )
        .length;
    final previousClients = data.clients
        .where(
          (client) => _isDateInPeriod(
            client.contractSignedAt,
            previousWeekStart,
            thisWeekStart,
          ),
        )
        .length;

    final thisLeadSeconds = _leadSecondsInPeriod(
      data.leadSessions,
      thisWeekStart,
      nextWeekStart,
    );
    final previousLeadSeconds = _leadSecondsInPeriod(
      data.leadSessions,
      previousWeekStart,
      thisWeekStart,
    );

    return _WeekDashboardStats(
      processedContracts: _WeekMetric(
        label: 'Umowy',
        value: thisClients,
        previousValue: previousClients,
      ),
      meetings: _WeekMetric(
        label: 'Spotkania',
        value: thisMeetings,
        previousValue: previousMeetings,
      ),
      fieldTime: _WeekMetric(
        label: 'Czas w terenie',
        value: thisLeadSeconds,
        previousValue: previousLeadSeconds,
        formatter: (seconds) => _formatDuration(Duration(seconds: seconds)),
      ),
    );
  }

  int _leadSecondsInPeriod(
    List<Map<String, dynamic>> sessions,
    DateTime start,
    DateTime end,
  ) {
    return sessions
        .where((session) {
          final date = DateTime.tryParse(
            session['session_date']?.toString() ?? '',
          );
          return _isDateInPeriod(date, start, end);
        })
        .fold<int>(
          0,
          (sum, session) =>
              sum + (session['work_seconds'] as num? ?? 0).toInt(),
        );
  }

  bool _isDashboardMeetingInPeriod(
    Contact contact,
    DateTime start,
    DateTime end,
  ) {
    return contact.status == 'scheduled_meeting' &&
        _isDateInPeriod(contact.contactDate, start, end);
  }

  bool _isDateInPeriod(DateTime? date, DateTime start, DateTime end) {
    if (date == null) return false;
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && day.isBefore(end);
  }

  DateTime _weekStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}

class _ActiveDashboardTile extends StatelessWidget {
  const _ActiveDashboardTile({
    required this.today,
    required this.dailyGoal,
    required this.isStarted,
    required this.isPaused,
    required this.elapsed,
    required this.currentMeetings,
    required this.currentContacts,
    required this.onStart,
    required this.onScheduleMeeting,
    required this.onAddLead,
  });

  final DateTime today;
  final int? dailyGoal;
  final bool isStarted;
  final bool isPaused;
  final Duration elapsed;
  final int currentMeetings;
  final int currentContacts;
  final VoidCallback onStart;
  final VoidCallback onScheduleMeeting;
  final VoidCallback onAddLead;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/active-lead-session-bg.webp',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.expand();
              },
            ),
          ),
          Positioned.fill(
            child: Container(color: appWorkDark.withValues(alpha: 0.70)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: appSuccess,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${_shortDate(today)} | ${_weekdayNameFull(today)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: appSurfaceSoft,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Leadowanie',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: appSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            [
                              'Obecny cel: $currentMeetings/$dailyGoal',
                              'Kontakty: $currentContacts',
                              _formatDuration(elapsed),
                            ].join(' | '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: appWorkText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    _LeadTimerControls(isStarted: isStarted, onStart: onStart),
                    if (isStarted)
                      _ActiveLeadButtons(
                        onScheduleMeeting: onScheduleMeeting,
                        onAddLead: onAddLead,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBodyPadding extends StatelessWidget {
  const _DashboardBodyPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: child,
    );
  }
}

class _ActiveLeadButtons extends StatelessWidget {
  const _ActiveLeadButtons({
    required this.onScheduleMeeting,
    required this.onAddLead,
  });

  final VoidCallback onScheduleMeeting;
  final VoidCallback onAddLead;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActiveLeadButton(
          label: 'Umów spotkanie',
          icon: Icons.event_available_outlined,
          onPressed: onScheduleMeeting,
          filled: true,
        ),
        const SizedBox(height: 6),
        _ActiveLeadButton(
          label: 'Dodaj kontakt',
          icon: Icons.person_add_alt_1_outlined,
          onPressed: onAddLead,
        ),
      ],
    );
  }
}

class _ActiveLeadButton extends StatelessWidget {
  const _ActiveLeadButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = filled ? appSuccess : appSurface;
    final foregroundColor = filled ? appSurface : appTextPrimary;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 92, maxWidth: 118),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foregroundColor),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

class _LeadTimerControls extends StatelessWidget {
  const _LeadTimerControls({required this.isStarted, required this.onStart});

  final bool isStarted;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    if (isStarted) return const SizedBox.shrink();

    return _LeadControlButton(
      label: 'Start',
      icon: Icons.play_arrow_rounded,
      onPressed: onStart,
      large: true,
    );
  }
}

class _LeadControlButton extends StatelessWidget {
  const _LeadControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.large = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final isStart = label == 'Start';
    final size = large ? (isStart ? 70.0 : 82.0) : 74.0;
    final backgroundColor = isStart ? appSuccess : appSurface;
    final foregroundColor = isStart ? appSurface : appTextPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onPressed,
      child: Container(
        width: size,
        height: large ? (isStart ? 70 : 82) : 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(isStart ? 999 : 18),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foregroundColor, size: large ? 30 : 20),
            SizedBox(height: large ? 2 : 0),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDashboardStats {
  const _WeekDashboardStats({
    required this.processedContracts,
    required this.meetings,
    required this.fieldTime,
  });

  final _WeekMetric processedContracts;
  final _WeekMetric meetings;
  final _WeekMetric fieldTime;

  int get total => processedContracts.value + meetings.value;
  int get previousTotal =>
      processedContracts.previousValue + meetings.previousValue;
}

class _WeekMetric {
  const _WeekMetric({
    required this.label,
    required this.value,
    required this.previousValue,
    this.formatter,
  });

  final String label;
  final int value;
  final int previousValue;
  final String Function(int value)? formatter;

  int get difference => value - previousValue;
  String get displayValue =>
      formatter == null ? value.toString() : formatter!(value);
}

class _WeeklyDashboardTile extends StatelessWidget {
  const _WeeklyDashboardTile({
    required this.stats,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  final _WeekDashboardStats stats;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurface,
        border: Border.all(color: appBorderStrong),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.processedContracts.value.toString(),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          _WeekComparisonText(
            currentValue: stats.processedContracts.value,
            previousValue: stats.processedContracts.previousValue,
            prefix: 'Umowy przeprocesowane',
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _WeekMetricBox(metric: stats.processedContracts),
                ),
                const SizedBox(width: 6),
                Expanded(child: _WeekMetricBox(metric: stats.meetings)),
                const SizedBox(width: 6),
                Expanded(child: _WeekMetricBox(metric: stats.fieldTime)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekMetricBox extends StatelessWidget {
  const _WeekMetricBox({required this.metric});

  final _WeekMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: appSurfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WeekChangeBadge(
            currentValue: metric.value,
            previousValue: metric.previousValue,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.displayValue,
              maxLines: 1,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),

          Text(
            metric.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: appTextSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekComparisonText extends StatelessWidget {
  const _WeekComparisonText({
    required this.currentValue,
    required this.previousValue,
    required this.prefix,
  });

  final int currentValue;
  final int previousValue;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final difference = currentValue - previousValue;
    final percent = _changePercent(currentValue, previousValue);
    final sign = difference > 0 ? '+' : '';

    return Text(
      '$prefix: $sign$difference / $sign$percent% vs poprzedni tydzień',
      style: TextStyle(
        color: difference >= 0 ? appBrand : appDanger,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _WeekChangeBadge extends StatelessWidget {
  const _WeekChangeBadge({
    required this.currentValue,
    required this.previousValue,
  });

  final int currentValue;
  final int previousValue;

  @override
  Widget build(BuildContext context) {
    final difference = currentValue - previousValue;
    final percent = _changePercent(currentValue, previousValue);
    final sign = difference > 0 ? '+' : '';
    final color = difference >= 0 ? appBrand : appDanger;

    return Text(
      '$sign$difference / $sign$percent%',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

int _changePercent(int currentValue, int previousValue) {
  if (previousValue == 0) {
    return currentValue == 0 ? 0 : 100;
  }
  return (((currentValue - previousValue) / previousValue) * 100).round();
}

class _DashboardList extends StatelessWidget {
  const _DashboardList({
    required this.title,
    required this.emptyText,
    required this.contacts,
    required this.onDelete,
    this.headerTrailing,
    this.onEditMeetingTime,
    this.leadingIcon,
    this.accentColor = appBrand,
    this.showExpandAction = false,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  final String title;
  final String? headerTrailing;
  final String emptyText;
  final List<Contact> contacts;
  final ValueChanged<Contact> onDelete;
  final ValueChanged<Contact>? onEditMeetingTime;
  final IconData? leadingIcon;
  final Color accentColor;
  final bool showExpandAction;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final useSplitMeetingTiles = onEditMeetingTime != null;

    if (showExpandAction && !isExpanded) return const SizedBox.shrink();

    if (useSplitMeetingTiles) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contacts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: appSurface,
                border: Border.all(color: appBorderStrong),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  emptyText,
                  style: const TextStyle(color: appTextSecondary),
                ),
              ),
            )
          else
            for (var index = 0; index < contacts.length; index++) ...[
              if (index > 0) const SizedBox(height: 10),
              _RecentContactTile(
                contact: contacts[index],
                onDelete: () => onDelete(contacts[index]),
                onEditMeetingTime: useSplitMeetingTiles
                    ? () => onEditMeetingTime!(contacts[index])
                    : null,
              ),
            ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: appSurface,
        border: Border.all(color: appBorderStrong),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contacts.isEmpty)
            SizedBox(
              width: double.infinity,
              child: Text(
                emptyText,
                style: const TextStyle(color: appTextSecondary),
              ),
            )
          else
            for (var index = 0; index < contacts.length; index++) ...[
              if (index > 0)
                const Divider(height: 10, thickness: 1, color: appBorder),
              _RecentContactTile(
                contact: contacts[index],
                onDelete: () => onDelete(contacts[index]),
              ),
            ],
        ],
      ),
    );
  }
}

class _RecentContactTile extends StatelessWidget {
  const _RecentContactTile({
    required this.contact,
    required this.onDelete,
    this.onEditMeetingTime,
  });

  final Contact contact;
  final VoidCallback onDelete;
  final VoidCallback? onEditMeetingTime;

  @override
  Widget build(BuildContext context) {
    final isMeeting = _isMeetingStatus(contact.status);
    final useMeetingLayout = isMeeting && onEditMeetingTime != null;
    final trailingText = isMeeting
        ? (contact.contactTime.length >= 5
              ? contact.contactTime.substring(0, 5)
              : contact.contactTime)
        : _statusByValue(contact.status).label;

    return Dismissible(
      key: ValueKey('dashboard-contact-${contact.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: appDanger,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: appSurface),
      ),
      onDismissed: (_) => onDelete(),
      child: useMeetingLayout
          ? _MeetingDashboardTileContent(
              contact: contact,
              timeText: trailingText,
              onEditMeetingTime: onEditMeetingTime,
            )
          : _ContactDashboardTileContent(
              contact: contact,
              trailingText: trailingText,
            ),
    );
  }
}

class _MeetingDashboardTileContent extends StatelessWidget {
  const _MeetingDashboardTileContent({
    required this.contact,
    required this.timeText,
    required this.onEditMeetingTime,
  });

  final Contact contact;
  final String timeText;
  final VoidCallback? onEditMeetingTime;

  @override
  Widget build(BuildContext context) {
    final note = contact.note.trim();

    return Material(
      color: appSurfaceSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: appBorderStrong),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showContactDetailsSheet(context, contact),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10, // lewy i prawy
            vertical: 8, // górny i dolny
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onEditMeetingTime,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Text(
                        timeText,
                        style: const TextStyle(
                          color: appBrand,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DashboardContactTitle(
                      contact: contact,
                      titleFontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Nawiguj',
                        visualDensity: VisualDensity.compact,
                        onPressed: contact.address.isEmpty
                            ? null
                            : () => _openMap(context, contact.address),
                        icon: const Icon(Icons.home_outlined),
                      ),
                      IconButton(
                        tooltip: 'Zadzwoń',
                        visualDensity: VisualDensity.compact,
                        onPressed: contact.phone.isEmpty
                            ? null
                            : () => _callPhone(context, contact.phone),
                        icon: const Icon(Icons.phone_outlined),
                      ),
                    ],
                  ),
                ],
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Divider(height: 1, thickness: 1, color: appBorder),
                const SizedBox(height: 4),
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: appTextSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardContactTitle extends StatelessWidget {
  const _DashboardContactTitle({required this.contact, this.titleFontSize});

  final Contact contact;
  final double? titleFontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      contact.contactName.isEmpty ? 'Bez nazwy' : contact.contactName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: appTextPrimary,
        fontWeight: FontWeight.w900,
      ).copyWith(fontSize: titleFontSize),
    );
  }
}

class _ContactDashboardTileContent extends StatelessWidget {
  const _ContactDashboardTileContent({
    required this.contact,
    required this.trailingText,
  });

  final Contact contact;
  final String trailingText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: appSurfaceSoft,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showContactDetailsSheet(context, contact),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: appBrandSoft,
                foregroundColor: appBrand,
                child: Text(
                  _initials(contact.contactName),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _DashboardContactText(contact: contact)),
              const SizedBox(width: 8),
              Text(
                trailingText,
                style: const TextStyle(
                  color: appBrand,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardContactText extends StatelessWidget {
  const _DashboardContactText({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final subtitle = _dashboardContactSubtitle(context, contact);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contact.contactName.isEmpty ? 'Bez nazwy' : contact.contactName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: appTextPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: appTextSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

String _dashboardContactSubtitle(BuildContext context, Contact contact) {
  if (_isMeetingStatus(contact.status)) {
    return contact.note;
  }

  final parts = <String>[];
  if (contact.contactDate != null && contact.contactTime.isNotEmpty) {
    parts.add(_displayDateTime(contact.contactDate!, contact.contactTime));
  } else if (contact.contactNotification != null) {
    parts.add(
      _displayDateTime(
        contact.contactNotification!,
        TimeOfDay.fromDateTime(contact.contactNotification!).format(context),
      ),
    );
  }
  if (contact.address.isNotEmpty) parts.add(contact.address);
  if (contact.note.isNotEmpty) parts.add(contact.note);
  return parts.join(' | ');
}

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key, required this.onContactRestored});

  final VoidCallback onContactRestored;

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  late Future<List<Client>> _clientsFuture;
  List<Client> _clientsCache = [];

  @override
  void initState() {
    super.initState();
    _clientsFuture = _fetchClients();
  }

  Future<List<Client>> _fetchClients() async {
    final data = await _supabase
        .from('clients')
        .select()
        .isFilter('archived_at', null);

    final clients = (data as List)
        .map((item) => Client.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    _clientsCache = clients;
    return clients;
  }

  void _reload() {
    setState(() => _clientsFuture = _fetchClients());
  }

  void _updateClientInList(Client updatedClient) {
    final nextClients = [
      for (final client in _clientsCache)
        if (client.id == updatedClient.id) updatedClient else client,
    ];

    setState(() {
      _clientsCache = nextClients;
      _clientsFuture = Future.value(nextClients);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      child: FutureBuilder<List<Client>>(
        future: _clientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              text: 'Nie udało się pobrać realizacji.',
              detail: snapshot.error.toString(),
            );
          }

          final clients = snapshot.data ?? [];
          if (clients.isEmpty) {
            return const _EmptyState(
              icon: Icons.precision_manufacturing_outlined,
              text: 'Nie masz jeszcze realizacji.',
              detail:
                  'Przesuń kontakt w prawo, gdy umowa jest gotowa do realizacji.',
            );
          }

          final activeClients = clients.where(_isActiveRealization).toList();
          final completedClients = clients
              .where((client) => !_isActiveRealization(client))
              .toList();

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _RealizationQueueIntro(
                  activeCount: activeClients.length,
                  completedCount: completedClients.length,
                ),
                const SizedBox(height: 12),
                if (activeClients.isEmpty)
                  const _EmptyState(
                    icon: Icons.task_alt_outlined,
                    text: 'Brak aktywnych realizacji.',
                    detail: 'Zakończone sprawy są niżej, poza główną kolejką.',
                  )
                else
                  for (var index = 0; index < activeClients.length; index++)
                    _ClientTile(
                      client: activeClients[index],
                      onClientChanged: _updateClientInList,
                    ),
                if (completedClients.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _CompletedRealizationsShelf(clients: completedClients),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

bool _isActiveRealization(Client client) {
  return client.status != 'installed' &&
      client.status != 'reported_to_grid_operator' &&
      client.status != 'subsidy_reported' &&
      client.status != 'lost';
}

class _RealizationQueueIntro extends StatelessWidget {
  const _RealizationQueueIntro({
    required this.activeCount,
    required this.completedCount,
  });

  final int activeCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appTextPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: appBrandSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.route_outlined, color: appBrand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kolejka realizacji',
                  style: TextStyle(
                    color: appSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$activeCount aktywne sprawy'
                  '${completedCount > 0 ? ' | $completedCount zakończone niżej' : ''}',
                  style: const TextStyle(
                    color: appWorkText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedRealizationsShelf extends StatelessWidget {
  const _CompletedRealizationsShelf({required this.clients});

  final List<Client> clients;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: appTextSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Zakończone realizacje: ${clients.length}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Text(
            'Lista później',
            style: TextStyle(
              color: appTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientTile extends StatefulWidget {
  const _ClientTile({required this.client, required this.onClientChanged});

  final Client client;
  final ValueChanged<Client> onClientChanged;

  @override
  State<_ClientTile> createState() => _ClientTileState();
}

class _ClientTileState extends State<_ClientTile> {
  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final statusStyle = _clientStatusStyle(client.status);
    final progress = _realizationProgress(client.status);
    final currentStage = _realizationStageNumber(client.status);
    final nextStage = _nextRealizationStageNumber(client);
    final currentStageName = _realizationShortStageName(client.status);
    final currentStageDate = _realizationStageDate(client);
    final nextStageName = _nextRealizationShortStageName(client);
    final realizationType = _executionMethodLabel(client.executionMethod);
    final address = client.installationAddress.isNotEmpty
        ? client.installationAddress
        : client.correspondenceAddress;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: statusStyle.color.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: statusStyle.color.withValues(alpha: 0.38)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final updatedClient = await showClientDetailsSheet(context, client);
            if (updatedClient != null) {
              widget.onClientChanged(updatedClient);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 122,
                  child: _RealizationStagePreview(
                    color: statusStyle.color,
                    currentStage: currentStage,
                    currentStageName: currentStageName,
                    currentStageDate: currentStageDate,
                    nextStage: nextStage,
                    nextStageName: nextStageName,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          client.clientName.isEmpty
                              ? 'Bez nazwy'
                              : client.clientName,
                          if (client.phone.isNotEmpty) client.phone,
                        ].join(' | '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (address.isNotEmpty)
                        Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: appTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: appSurface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusStyle.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (client.productName.isNotEmpty ||
                          realizationType.isNotEmpty)
                        Text(
                          [
                            if (client.productName.isNotEmpty)
                              client.productName,
                            if (realizationType.isNotEmpty) realizationType,
                          ].join(' | '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: appTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RealizationStagePreview extends StatelessWidget {
  const _RealizationStagePreview({
    required this.color,
    required this.currentStage,
    required this.currentStageName,
    required this.currentStageDate,
    required this.nextStage,
    required this.nextStageName,
  });

  final Color color;
  final String currentStage;
  final String currentStageName;
  final String currentStageDate;
  final String nextStage;
  final String nextStageName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StageStepPill(
          number: currentStage,
          label: currentStageName,
          helper: currentStageDate,
          color: color,
          active: true,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 15, top: 5, bottom: 5),
          child: Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        _StageStepPill(
          number: nextStage,
          label: nextStageName,
          helper: '',
          color: color,
          active: false,
        ),
      ],
    );
  }
}

class _StageStepPill extends StatelessWidget {
  const _StageStepPill({
    required this.number,
    required this.label,
    required this.helper,
    required this.color,
    required this.active,
  });

  final String number;
  final String label;
  final String helper;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: active ? 32 : 28,
          height: active ? 32 : 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color : appSurface,
            shape: BoxShape.circle,
            border: active
                ? null
                : Border.all(color: color.withValues(alpha: 0.48)),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: active ? appSurface : color,
              fontSize: active ? 13 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? appTextPrimary : appTextSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              if (helper.isNotEmpty)
                Text(
                  helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: appTextSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _executionMethodLabel(String method) {
  return switch (method) {
    'gotowka' => 'Gotówkowy',
    'finansowanie' => 'Na raty',
    _ => '',
  };
}

String _executionMethodDetailsLabel(String method) {
  return switch (method) {
    'gotowka' => 'Klient gotówkowy',
    'finansowanie' => 'Klient na raty',
    _ => '',
  };
}

bool _isCashRealization(Client client) {
  return client.executionMethod == 'gotowka';
}

String _realizationStageDate(Client client) {
  final date = client.contractSignedAt;
  if (date == null) return '';
  return _shortDate(date);
}

String _stageTwoLabelFor(Client client) {
  return _isCashRealization(client) ? 'Zaliczka' : 'Finansowanie';
}

class _ClientStatusStyle {
  const _ClientStatusStyle(this.label, this.color);

  final String label;
  final Color color;
}

_ClientStatusStyle _clientStatusStyle(String status) {
  return switch (status) {
    'signed_contract' => const _ClientStatusStyle(
      'Spisana umowa',
      Color(0xFF2F5D50),
    ),
    'financing_approved' => const _ClientStatusStyle(
      'Po finansowaniu',
      Color(0xFF2563A9),
    ),
    'partial_payment_paid' => const _ClientStatusStyle(
      'Wpłacona zaliczka',
      Color(0xFF8A5A12),
    ),
    'welcome_call_done' => const _ClientStatusStyle(
      'Po telefonie powitalnym',
      Color(0xFF5B7CFA),
    ),
    'scheduling_installation' => const _ClientStatusStyle(
      'W trakcie umawiania montażu',
      Color(0xFFF0A202),
    ),
    'in_installation' => const _ClientStatusStyle(
      'W trakcie montażu',
      Color(0xFF7C3AED),
    ),
    'installed' => const _ClientStatusStyle(
      'Zamontowany / po montażu',
      Color(0xFF147D64),
    ),
    'reported_to_grid_operator' => const _ClientStatusStyle(
      'Zgłoszony do ZEI',
      Color(0xFF4B6584),
    ),
    'subsidy_reported' => const _ClientStatusStyle(
      'Przyznana dotacja',
      Color(0xFF0F766E),
    ),
    'lost' => const _ClientStatusStyle('Spad', Color(0xFF2E2D2A)),
    _ => _ClientStatusStyle(status, const Color(0xFF2F5D50)),
  };
}

double _realizationProgress(String status) {
  return switch (status) {
    'signed_contract' => 0.18,
    'financing_approved' => 0.28,
    'partial_payment_paid' => 0.28,
    'welcome_call_done' => 0.40,
    'scheduling_installation' => 0.55,
    'in_installation' => 0.70,
    'installed' => 0.82,
    'reported_to_grid_operator' => 0.92,
    'subsidy_reported' => 1.00,
    'lost' => 1.00,
    _ => 0.16,
  };
}

String _realizationStageNumber(String status) {
  return switch (status) {
    'signed_contract' => '1',
    'financing_approved' || 'partial_payment_paid' => '2',
    'welcome_call_done' => '3',
    'scheduling_installation' => '4',
    'in_installation' => '5',
    'installed' => '6',
    'reported_to_grid_operator' => '7',
    'subsidy_reported' => '8',
    'lost' => '!',
    _ => '1',
  };
}

String _nextRealizationStageNumber(Client client) {
  return switch (client.status) {
    'signed_contract' => '2',
    'financing_approved' || 'partial_payment_paid' => '3',
    'welcome_call_done' => '4',
    'scheduling_installation' => '5',
    'in_installation' => '6',
    'installed' => '7',
    'reported_to_grid_operator' => '8',
    'subsidy_reported' => '✓',
    'lost' => '✓',
    _ => '2',
  };
}

String _realizationShortStageName(String status) {
  return switch (status) {
    'signed_contract' => 'Spisana umowa',
    'financing_approved' => 'Finansowanie',
    'partial_payment_paid' => 'Zaliczka',
    'welcome_call_done' => 'Phone call',
    'scheduling_installation' => 'Umawianie',
    'in_installation' => 'Montaż',
    'installed' => 'Po montażu',
    'reported_to_grid_operator' => 'ZEI',
    'subsidy_reported' => 'Dotacja',
    'lost' => 'Spad',
    _ => 'Spisana umowa',
  };
}

String _nextRealizationShortStageName(Client client) {
  return switch (client.status) {
    'signed_contract' => _stageTwoLabelFor(client),
    'financing_approved' || 'partial_payment_paid' => 'Phone call',
    'welcome_call_done' => 'Umawianie',
    'scheduling_installation' => 'Montaż',
    'in_installation' => 'Po montażu',
    'installed' => 'ZEI',
    'reported_to_grid_operator' => 'Dotacja',
    'subsidy_reported' => 'Koniec',
    'lost' => 'Koniec',
    _ => 'Finansowanie',
  };
}

Future<Client?> showClientDetailsSheet(BuildContext context, Client client) {
  return showModalBottomSheet<Client>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ClientDetailsSheet(client: client),
  );
}

class ClientDetailsSheet extends StatefulWidget {
  const ClientDetailsSheet({super.key, required this.client});

  final Client client;

  @override
  State<ClientDetailsSheet> createState() => _ClientDetailsSheetState();
}

class _ClientDetailsSheetState extends State<ClientDetailsSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _correspondenceAddressController;
  late final TextEditingController _installationAddressController;
  late final TextEditingController _productController;
  late String _status;
  late String _executionMethod;
  bool _isEditing = false;
  bool _isSaving = false;
  late Client _currentClient;

  Client get client => _currentClient;

  @override
  void initState() {
    super.initState();
    _currentClient = widget.client;
    _nameController = TextEditingController(text: client.clientName);
    _phoneController = TextEditingController(text: client.phone);
    _correspondenceAddressController = TextEditingController(
      text: client.correspondenceAddress,
    );
    _installationAddressController = TextEditingController(
      text: client.installationAddress,
    );
    _productController = TextEditingController(text: client.productName);
    _status = client.status;
    _executionMethod = normalizeExecutionMethod(client.executionMethod);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _correspondenceAddressController.dispose();
    _installationAddressController.dispose();
    _productController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _supabase
          .from('clients')
          .update({
            'client_name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'correspondence_address': _correspondenceAddressController.text
                .trim(),
            'installation_address': _installationAddressController.text.trim(),
            'product_name': _productController.text.trim(),
            'execution_method': _executionMethod,
            'status': _status,
          })
          .eq('id', client.id);

      if (!mounted) return;
      final updatedClient = client.copyWith(
        clientName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        correspondenceAddress: _correspondenceAddressController.text.trim(),
        installationAddress: _installationAddressController.text.trim(),
        productName: _productController.text.trim(),
        executionMethod: _executionMethod,
        status: _status,
      );
      setState(() {
        _currentClient = updatedClient;
        _isEditing = false;
      });
      Navigator.of(context).pop(updatedClient);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = _clientStatusStyle(_status);
    final address = _installationAddressController.text.trim().isNotEmpty
        ? _installationAddressController.text.trim()
        : _correspondenceAddressController.text.trim();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: statusStyle.color.withValues(alpha: 0.14),
                  foregroundColor: statusStyle.color,
                  child: Text(_initials(client.clientName)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.trim().isEmpty
                            ? 'Bez nazwy'
                            : _nameController.text.trim(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusStyle.label,
                        style: TextStyle(
                          color: statusStyle.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => setState(() => _isEditing = !_isEditing),
                  icon: Icon(_isEditing ? Icons.close : Icons.edit),
                  label: Text(_isEditing ? 'Zamknij' : 'Edytuj'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_phoneController.text.trim().isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _callPhone(context, _phoneController.text.trim()),
                      icon: const Icon(Icons.phone),
                      label: const Text('Zadzwoń'),
                    ),
                  ),
                if (_phoneController.text.trim().isNotEmpty &&
                    address.isNotEmpty)
                  const SizedBox(width: 10),
                if (address.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openMap(context, address),
                      icon: const Icon(Icons.home),
                      label: const Text('Nawiguj'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _isEditing ? _buildEditView() : _buildPreviewCards(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCards() {
    final statusStyle = _clientStatusStyle(_status);

    return Column(
      key: const ValueKey('client-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClientInfoCard(
          icon: Icons.person,
          title: 'Dane realizacji',
          rows: [
            _InfoLine('Imię i nazwisko', _nameController.text.trim()),
            _InfoLine('Nr telefonu', _phoneController.text.trim()),
          ],
        ),
        const SizedBox(height: 10),
        _ClientInfoCard(
          icon: Icons.home,
          title: 'Adresy',
          rows: [
            _InfoLine(
              'Adres korespondencyjny',
              _correspondenceAddressController.text.trim(),
            ),
            _InfoLine(
              'Adres montażu',
              _installationAddressController.text.trim(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ClientInfoCard(
          icon: Icons.assignment_turned_in,
          title: 'Umowa',
          accentColor: statusStyle.color,
          rows: [
            _InfoLine('Produkt', _productController.text.trim()),
            _InfoLine(
              'Typ klienta',
              _executionMethodDetailsLabel(_executionMethod),
            ),
            _InfoLine('Status', statusStyle.label),
            _InfoLine(
              'Data podpisania',
              client.contractSignedAt == null
                  ? ''
                  : _shortDate(client.contractSignedAt!),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditView() {
    return Column(
      key: const ValueKey('client-edit'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Imię i nazwisko'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Nr telefonu'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _correspondenceAddressController,
          decoration: const InputDecoration(
            labelText: 'Adres korespondencyjny',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _installationAddressController,
          decoration: const InputDecoration(labelText: 'Adres montażu'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _productController,
          decoration: const InputDecoration(labelText: 'Produkt'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _executionMethod,
          decoration: const InputDecoration(labelText: 'Typ klienta'),
          items: const [
            DropdownMenuItem(value: 'gotowka', child: Text('Gotówkowy')),
            DropdownMenuItem(value: 'finansowanie', child: Text('Na raty')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _executionMethod = value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Status realizacji'),
          items: const [
            DropdownMenuItem(
              value: 'signed_contract',
              child: Text('Spisana umowa'),
            ),
            DropdownMenuItem(
              value: 'financing_approved',
              child: Text('Po finansowaniu'),
            ),
            DropdownMenuItem(
              value: 'partial_payment_paid',
              child: Text('Wpłacona zaliczka'),
            ),
            DropdownMenuItem(
              value: 'welcome_call_done',
              child: Text('Po telefonie powitalnym'),
            ),
            DropdownMenuItem(
              value: 'scheduling_installation',
              child: Text('W trakcie umawiania montażu'),
            ),
            DropdownMenuItem(
              value: 'in_installation',
              child: Text('W trakcie montażu'),
            ),
            DropdownMenuItem(
              value: 'installed',
              child: Text('Zamontowany / po montażu'),
            ),
            DropdownMenuItem(
              value: 'reported_to_grid_operator',
              child: Text('Zgłoszony do ZEI'),
            ),
            DropdownMenuItem(
              value: 'subsidy_reported',
              child: Text('Przyznana dotacja'),
            ),
            DropdownMenuItem(value: 'lost', child: Text('Spad')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _status = value);
          },
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? 'Zapisuję...' : 'Zapisz zmiany'),
        ),
      ],
    );
  }
}

class _InfoLine {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;
}

class _ClientInfoCard extends StatelessWidget {
  const _ClientInfoCard({
    required this.icon,
    required this.title,
    required this.rows,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final List<_InfoLine> rows;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows
        .where((row) => row.value.trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor ?? appBorderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accentColor ?? appBrand),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (visibleRows.isEmpty)
            const Text('Brak danych', style: TextStyle(color: appTextSecondary))
          else
            for (final row in visibleRows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DetailRow(label: row.label, value: row.value),
              ),
        ],
      ),
    );
  }
}

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key, required this.refreshSignal});

  final int refreshSignal;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  late Future<List<Contact>> _contactsFuture;
  final Set<String> _selectedContactIds = {};
  final Set<String> _hiddenStatuses = {};
  final Map<String, List<String>> _contactOrderByStatus = {};
  late List<String> _statusOrder;
  int _contactTilesResetSignal = 0;

  @override
  void initState() {
    super.initState();
    _statusOrder = _contactStatuses.map((status) => status.value).toList();
    _contactsFuture = _fetchContacts();
  }

  @override
  void didUpdateWidget(covariant ContactsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _reload();
    }
  }

  Future<List<Contact>> _fetchContacts() async {
    final data = await _supabase
        .from('contacts')
        .select()
        .isFilter('archived_at', null)
        .isFilter('moved_to_client_at', null);

    return (data as List)
        .map((item) => Contact.fromMap(Map<String, dynamic>.from(item)))
        .where((contact) => !_isMeetingStatus(contact.status))
        .toList();
  }

  void _reload() {
    setState(() {
      _contactsFuture = _fetchContacts();
    });
  }

  void _resetOpenContactTiles() {
    setState(() => _contactTilesResetSignal++);
  }

  Future<void> _archiveContact(Contact contact) async {
    await _supabase
        .from('contacts')
        .update({'archived_at': DateTime.now().toIso8601String()})
        .eq('id', contact.id);
    _reload();
  }

  Future<void> _deleteContact(Contact contact) async {
    await _supabase.from('contacts').delete().eq('id', contact.id);
    _reload();
  }

  Future<void> _addContactToClients(Contact contact) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('clients').insert({
      'agent_id': user.id,
      'source_contact_id': contact.id,
      'client_name': contact.contactName,
      'phone': contact.phone,
      'correspondence_address': contact.address,
      'installation_address': contact.address,
      'product_name': '',
      'contract_signed_at': _dateOnly(DateTime.now()),
      'execution_method': 'finansowanie',
      'status': 'signed_contract',
    });

    await _supabase
        .from('contacts')
        .update({'moved_to_client_at': DateTime.now().toIso8601String()})
        .eq('id', contact.id);

    _reload();
  }

  Future<void> _archiveSelected() async {
    final count = _selectedContactIds.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Przenieść do archiwum?'),
        content: Text('Zaznaczone kontakty: $count.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Przenieś'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _supabase
        .from('contacts')
        .update({'archived_at': DateTime.now().toIso8601String()})
        .inFilter('id', _selectedContactIds.toList());

    setState(_selectedContactIds.clear);
    _reload();
  }

  void _toggleContactSelection(Contact contact) {
    setState(() {
      if (_selectedContactIds.contains(contact.id)) {
        _selectedContactIds.remove(contact.id);
      } else {
        _selectedContactIds.add(contact.id);
      }
    });
  }

  void _toggleStatusVisibility(String status) {
    setState(() {
      if (_hiddenStatuses.contains(status)) {
        _hiddenStatuses.remove(status);
      } else {
        _hiddenStatuses.add(status);
      }
    });
  }

  void _moveStatusBefore(String draggedStatus, String targetStatus) {
    if (draggedStatus == targetStatus) return;

    setState(() {
      final oldIndex = _statusOrder.indexOf(draggedStatus);
      final newIndex = _statusOrder.indexOf(targetStatus);
      if (oldIndex == -1 || newIndex == -1) return;

      final status = _statusOrder.removeAt(oldIndex);
      _statusOrder.insert(newIndex, status);
    });
  }

  void _reorderContactInStatus(String status, int oldIndex, int newIndex) {
    setState(() {
      final order = _contactOrderByStatus.putIfAbsent(status, () => []);
      final contactId = order.removeAt(oldIndex);
      order.insert(newIndex, contactId);
    });
  }

  List<Contact> _orderedContactsForStatus(
    List<Contact> contacts,
    String status,
  ) {
    final statusContacts = contacts
        .where((contact) => contact.status == status)
        .toList();
    final knownIds = statusContacts.map((contact) => contact.id).toSet();
    final savedOrder = _contactOrderByStatus.putIfAbsent(status, () => []);
    savedOrder.removeWhere((id) => !knownIds.contains(id));

    for (final contact in statusContacts) {
      if (!savedOrder.contains(contact.id)) {
        savedOrder.add(contact.id);
      }
    }

    final byId = {for (final contact in statusContacts) contact.id: contact};
    return [
      for (final id in savedOrder)
        if (byId[id] != null) byId[id]!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      child: FutureBuilder<List<Contact>>(
        future: _contactsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              text: 'Nie udało się pobrać kontaktów.',
              detail: snapshot.error.toString(),
            );
          }

          final contacts = snapshot.data ?? [];
          final statusesWithContacts = contacts
              .map((contact) => contact.status)
              .toSet();
          final visibleStatusOrder = _statusOrder
              .where(statusesWithContacts.contains)
              .toList();
          final orderedStatuses = visibleStatusOrder
              .map(_statusByValue)
              .toList();

          if (contacts.isEmpty) {
            return const _EmptyState(
              icon: Icons.contacts_outlined,
              text: 'Nie masz jeszcze kontaktów.',
              detail: 'Kliknij plus i dodaj pierwszy kontakt.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _resetOpenContactTiles,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  if (_selectedContactIds.isNotEmpty) ...[
                    _SelectedContactsBar(
                      count: _selectedContactIds.length,
                      onArchive: _archiveSelected,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _StatusVisibilityBar(
                    statusOrder: visibleStatusOrder,
                    hiddenStatuses: _hiddenStatuses,
                    onToggle: _toggleStatusVisibility,
                    onMoveBefore: _moveStatusBefore,
                  ),
                  const SizedBox(height: 18),
                  for (final status in orderedStatuses)
                    AnimatedSwitcher(
                      key: ValueKey('switch-${status.value}'),
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          alignment: AlignmentDirectional.topStart,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _hiddenStatuses.contains(status.value)
                          ? const SizedBox.shrink()
                          : _ContactStatusSection(
                              key: ValueKey('section-${status.value}'),
                              status: status,
                              contacts: _orderedContactsForStatus(
                                contacts,
                                status.value,
                              ),
                              selectedContactIds: _selectedContactIds,
                              onArchive: _archiveContact,
                              onAddToClients: _addContactToClients,
                              onDelete: _deleteContact,
                              onToggleSelection: _toggleContactSelection,
                              resetSignal: _contactTilesResetSignal,
                              onReorder: (oldIndex, newIndex) =>
                                  _reorderContactInStatus(
                                    status.value,
                                    oldIndex,
                                    newIndex,
                                  ),
                            ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusVisibilityBar extends StatelessWidget {
  const _StatusVisibilityBar({
    required this.statusOrder,
    required this.hiddenStatuses,
    required this.onToggle,
    required this.onMoveBefore,
  });

  final List<String> statusOrder;
  final Set<String> hiddenStatuses;
  final ValueChanged<String> onToggle;
  final void Function(String draggedStatus, String targetStatus) onMoveBefore;

  static const double _circleSize = 42;
  static const double _gap = 8;
  static const double _slotWidth = _circleSize + _gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: statusOrder.length * _slotWidth,
          height: 48,
          child: Stack(
            children: [
              for (var index = 0; index < statusOrder.length; index++)
                _AnimatedStatusSlot(
                  key: ValueKey(statusOrder[index]),
                  left: index * _slotWidth,
                  status: _statusByValue(statusOrder[index]),
                  isHidden: hiddenStatuses.contains(statusOrder[index]),
                  onToggle: onToggle,
                  onMoveBefore: onMoveBefore,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedContactsBar extends StatelessWidget {
  const _SelectedContactsBar({required this.count, required this.onArchive});

  final int count;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: appSurfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Zaznaczone kontakty: $count',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onArchive,
            icon: const Icon(Icons.archive_outlined, size: 18),
            label: const Text('Archiwum'),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStatusSlot extends StatelessWidget {
  const _AnimatedStatusSlot({
    super.key,
    required this.left,
    required this.status,
    required this.isHidden,
    required this.onToggle,
    required this.onMoveBefore,
  });

  final double left;
  final ContactStatus status;
  final bool isHidden;
  final ValueChanged<String> onToggle;
  final void Function(String draggedStatus, String targetStatus) onMoveBefore;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeOutCubic,
      left: left,
      top: 3,
      width: 42,
      height: 42,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          if (details.data != status.value) {
            onMoveBefore(details.data, status.value);
          }
          return true;
        },
        builder: (context, candidateData, rejectedData) {
          return Draggable<String>(
            data: status.value,
            feedback: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: _StatusCircle(
                status: status,
                isHidden: isHidden,
                scale: 1.08,
              ),
            ),
            childWhenDragging: _StatusCirclePlaceholder(
              color: status.color,
              isHidden: isHidden,
            ),
            child: Tooltip(
              message: status.label,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onToggle(status.value),
                child: _StatusCircle(status: status, isHidden: isHidden),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusCirclePlaceholder extends StatelessWidget {
  const _StatusCirclePlaceholder({required this.color, required this.isHidden});

  final Color color;
  final bool isHidden;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: (isHidden ? appBorderStrong : color).withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(
          color: (isHidden ? appBorderStrong : color).withValues(alpha: 0.26),
        ),
      ),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  const _StatusCircle({
    required this.status,
    required this.isHidden,
    this.scale = 1,
  });

  final ContactStatus status;
  final bool isHidden;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isHidden ? appBorderStrong : status.color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isHidden ? Icons.visibility_off : Icons.visibility,
            color: appSurface.withValues(alpha: isHidden ? 0.34 : 0.24),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ContactStatusSection extends StatelessWidget {
  const _ContactStatusSection({
    super.key,
    required this.status,
    required this.contacts,
    required this.selectedContactIds,
    required this.onArchive,
    required this.onAddToClients,
    required this.onDelete,
    required this.onToggleSelection,
    required this.resetSignal,
    required this.onReorder,
  });

  final ContactStatus status;
  final List<Contact> contacts;
  final Set<String> selectedContactIds;
  final Future<void> Function(Contact contact) onArchive;
  final Future<void> Function(Contact contact) onAddToClients;
  final Future<void> Function(Contact contact) onDelete;
  final ValueChanged<Contact> onToggleSelection;
  final int resetSignal;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status.label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Text(
                '${contacts.length}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: appTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: contacts.length,
            onReorderItem: onReorder,
            proxyDecorator: (child, index, animation) {
              return ScaleTransition(
                scale: Tween<double>(begin: 1, end: 1.02).animate(animation),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ReorderableDragStartListener(
                key: ValueKey('tile-${contact.id}'),
                index: index,
                child: _ContactTile(
                  contact: contact,
                  isSelected: selectedContactIds.contains(contact.id),
                  isSelectionMode: selectedContactIds.isNotEmpty,
                  onArchive: () => onArchive(contact),
                  onAddToClients: () => onAddToClients(contact),
                  onDelete: () => onDelete(contact),
                  onToggleSelection: () => onToggleSelection(contact),
                  resetSignal: resetSignal,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatefulWidget {
  const _ContactTile({
    required this.contact,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onArchive,
    required this.onAddToClients,
    required this.onDelete,
    required this.onToggleSelection,
    required this.resetSignal,
  });

  final Contact contact;
  final bool isSelected;
  final bool isSelectionMode;
  final Future<void> Function() onArchive;
  final Future<void> Function() onAddToClients;
  final Future<void> Function() onDelete;
  final VoidCallback onToggleSelection;
  final int resetSignal;

  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  bool _leftActionsOpen = false;
  bool _rightActionsOpen = false;
  double _dragOffset = 0;

  static const double _actionsWidth = 154;
  static const double _clientActionWidth = 86;

  @override
  void didUpdateWidget(covariant _ContactTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetSignal != widget.resetSignal) {
      setState(() {
        _leftActionsOpen = false;
        _rightActionsOpen = false;
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;
    final status = _statusByValue(contact.status);
    final subtitle = _contactSubtitle(contact);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            final nextOffset = _dragOffset + details.delta.dx;
            _dragOffset = nextOffset.clamp(-_actionsWidth, _clientActionWidth);
            _leftActionsOpen = _dragOffset > 42;
            _rightActionsOpen = _dragOffset < -72;
          });
        },
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (_dragOffset > 72 || velocity > 1100) {
            setState(() {
              _dragOffset = _clientActionWidth;
              _leftActionsOpen = true;
              _rightActionsOpen = false;
            });
          } else if (_dragOffset < -118 || velocity < -1100) {
            setState(() {
              _dragOffset = -_actionsWidth;
              _leftActionsOpen = false;
              _rightActionsOpen = true;
            });
          } else {
            setState(() {
              _dragOffset = 0;
              _leftActionsOpen = false;
              _rightActionsOpen = false;
            });
          }
        },
        onHorizontalDragCancel: () {
          setState(() {
            _dragOffset = _rightActionsOpen
                ? -_actionsWidth
                : _leftActionsOpen
                ? _clientActionWidth
                : 0;
          });
        },
        child: Stack(
          children: [
            Positioned.fill(
              left: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SwipeActionButton(
                  color: appBrand,
                  icon: Icons.add,
                  label: 'Klient',
                  onPressed: () => _confirmAddToClients(context),
                ),
              ),
            ),
            Positioned.fill(
              right: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SwipeActionButton(
                      color: appWarning,
                      icon: Icons.archive_outlined,
                      label: 'Archiwum',
                      onPressed: () => _confirmArchive(context),
                    ),
                    const SizedBox(width: 6),
                    _SwipeActionButton(
                      color: appDanger,
                      icon: Icons.close,
                      label: 'Usuń',
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_dragOffset, 0, 0),
              child: Material(
                color: widget.isSelected ? appBrandSoft : appSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: widget.isSelected ? appBrand : appBorderStrong,
                    width: widget.isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: widget.isSelectionMode
                      ? widget.onToggleSelection
                      : (_leftActionsOpen || _rightActionsOpen)
                      ? () => setState(() {
                          _leftActionsOpen = false;
                          _rightActionsOpen = false;
                          _dragOffset = 0;
                        })
                      : () => showContactDetailsSheet(context, contact),
                  onLongPress: widget.onToggleSelection,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        if (widget.isSelectionMode) ...[
                          Icon(
                            widget.isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: appBrand,
                          ),
                          const SizedBox(width: 10),
                        ],
                        CircleAvatar(
                          backgroundColor: status.color.withValues(alpha: 0.14),
                          foregroundColor: status.color,
                          child: Text(_initials(contact.contactName)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.contactName.isEmpty
                                    ? 'Bez nazwy'
                                    : contact.contactName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              if (subtitle.isNotEmpty)
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: appTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (contact.address.isNotEmpty &&
                            !widget.isSelectionMode) ...[
                          const SizedBox(width: 10),
                          IconButton(
                            tooltip: 'Nawiguj',
                            color: appBrand,
                            onPressed: () => _openMap(context, contact.address),
                            iconSize: 25,
                            icon: const Icon(Icons.home),
                          ),
                        ],
                        if (contact.phone.isNotEmpty &&
                            !widget.isSelectionMode) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Zadzwoń',
                            color: appBrand,
                            onPressed: () => _callPhone(context, contact.phone),
                            iconSize: 25,
                            icon: const Icon(Icons.phone),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await _confirmContactAction(
      context: context,
      title: 'Usunąć kontakt na stałe?',
      actionLabel: 'Usuń',
      actionColor: appDanger,
    );

    if (confirmed == true) {
      await widget.onDelete();
    }
  }

  Future<void> _confirmArchive(BuildContext context) async {
    final confirmed = await _confirmContactAction(
      context: context,
      title: 'Przenieść kontakt do archiwum?',
      actionLabel: 'Archiwum',
      actionColor: appWarning,
    );

    if (confirmed == true) {
      await widget.onArchive();
    }
  }

  Future<void> _confirmAddToClients(BuildContext context) async {
    final confirmed = await _confirmContactAction(
      context: context,
      title: 'Przenieść kontakt do realizacji?',
      actionLabel: 'Dodaj',
      actionColor: appBrand,
    );

    if (confirmed == true) {
      await widget.onAddToClients();
    }
  }

  Future<bool?> _confirmContactAction({
    required BuildContext context,
    required String title,
    required String actionLabel,
    required Color actionColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Czy na pewno? Akcji nie można odwrócić.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: actionColor),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  String _contactSubtitle(Contact contact) {
    if ((contact.status == 'scheduled_meeting' ||
            contact.status == 'meeting_active' ||
            contact.status == 'postponed') &&
        contact.contactDate != null &&
        contact.contactTime.isNotEmpty) {
      final parts = [
        _displayDateTime(contact.contactDate!, contact.contactTime),
        if (contact.contactQuality.isNotEmpty) contact.contactQuality,
      ];
      return parts.join(' | ');
    }

    if (contact.status == 'contact') {
      final parts = [
        if (contact.phone.isNotEmpty) contact.phone,
        if (contact.address.isNotEmpty) contact.address,
        if (contact.note.isNotEmpty) contact.note,
      ];
      return parts.join(' | ');
    }

    if (contact.status == 'interested') {
      return contact.note.isEmpty
          ? 'Klient chce, ale nie teraz. Wrócić z sugestią.'
          : contact.note;
    }

    if (contact.status == 'meeting_active') {
      return 'Spotkanie trwa... zakończ je wynikiem.';
    }

    return contact.note;
  }
}

class _ContactStatusPill extends StatelessWidget {
  const _ContactStatusPill({required this.status});

  final ContactStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.color.withValues(alpha: 0.22)),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: status.color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 74,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: appSurface, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: appSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showContactDetailsSheet(BuildContext context, Contact contact) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ContactDetailsSheet(contact: contact),
  );
}

class ContactDetailsSheet extends StatefulWidget {
  const ContactDetailsSheet({super.key, required this.contact});

  final Contact contact;

  @override
  State<ContactDetailsSheet> createState() => _ContactDetailsSheetState();
}

class _ContactDetailsSheetState extends State<ContactDetailsSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _noteController;
  late String _status;
  late DateTime _contactDate;
  late TimeOfDay _contactTime;
  String? _contactQuality;
  bool _isSaving = false;

  Contact get contact => widget.contact;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: contact.contactName);
    _phoneController = TextEditingController(text: contact.phone);
    _addressController = TextEditingController(text: contact.address);
    _noteController = TextEditingController(text: contact.note);
    _status = contact.status == 'signed_contract'
        ? 'scheduled_meeting'
        : contact.status;
    _contactDate =
        contact.contactDate ?? DateTime.now().add(const Duration(days: 1));
    _contactTime = _timeOfDayFromText(contact.contactTime);
    _contactQuality = contact.contactQuality.isEmpty
        ? null
        : contact.contactQuality;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      final payload = <String, dynamic>{
        'contact_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'status': _status,
        'note': _noteController.text.trim(),
        'contact_date': null,
        'contact_time': null,
        'meeting_time': null,
        'contact_quality': null,
        'contact_notification': null,
      };

      if (_status == 'scheduled_meeting') {
        payload.addAll({
          'contact_date': _dateOnly(_contactDate),
          'contact_time': _timeOnly(_contactTime),
          'meeting_time': _timeOnly(_contactTime),
          'contact_quality': _contactQuality,
        });
      }

      await _supabase.from('contacts').update(payload).eq('id', contact.id);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kontakt został zapisany.')));
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateContact(Map<String, dynamic> payload) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _supabase.from('contacts').update(payload).eq('id', contact.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kontakt został zaktualizowany.')),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _startMeeting() async {
    await _updateContact({
      'status': 'meeting_active',
      'note': _mergeNote('Start spotkania: ${_formatDuration(Duration.zero)}'),
    });
  }

  Future<void> _postponeMeeting() async {
    final date = await _askPostponedDate();
    if (!mounted) return;

    if (date == null) {
      await _updateContact({
        'status': 'postponed',
        'contact_notification': DateTime.now()
            .add(const Duration(hours: 4))
            .toIso8601String(),
        'note': _mergeNote(
          'Przełożone: ustalić nowy termin przed zamknięciem cyklu.',
        ),
      });
      return;
    }

    await _updateContact({
      'status': 'scheduled_meeting',
      'contact_date': _dateOnly(date),
      'contact_time': _timeOnly(_contactTime),
      'meeting_time': _timeOnly(_contactTime),
      'contact_quality': _contactQuality,
      'contact_notification': null,
      'note': _mergeNote(
        'Przełożone na ${_shortDate(date)} (${_weekdayName(date)}).',
      ),
    });
  }

  Future<DateTime?> _askPostponedDate() async {
    final hasDate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masz nowy termin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nie teraz'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tak'),
          ),
        ],
      ),
    );

    if (hasDate != true || !mounted) return null;
    return showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  Future<void> _finishMeeting() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jaki jest wynik spotkania?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MeetingResultButton(
              icon: Icons.assignment_turned_in_outlined,
              label: 'Spisana umowa',
              color: appSuccess,
              onTap: () => Navigator.pop(context, 'signed_contract'),
            ),
            const SizedBox(height: 10),
            _MeetingResultButton(
              icon: Icons.trending_up_outlined,
              label: 'Zainteresowany',
              color: appInfo,
              onTap: () => Navigator.pop(context, 'interested'),
            ),
            const SizedBox(height: 10),
            _MeetingResultButton(
              icon: Icons.do_not_disturb_on_outlined,
              label: 'Nie zainteresowany',
              color: appDanger,
              onTap: () => Navigator.pop(context, 'not_interested'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    if (result == 'signed_contract') {
      await _finishSignedContract();
    } else if (result == 'interested') {
      await _updateContact({
        'status': 'interested',
        'note': _mergeNote(
          'Wynik spotkania: zainteresowany. Wrócić z kontekstową sugestią.',
        ),
      });
    } else {
      await _finishNotInterested();
    }
  }

  Future<void> _finishSignedContract() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Przenieść do W realizacji?'),
        content: const Text(
          'Spotkanie zostanie zapisane jako odbyte i z umową.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nie teraz'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Przenieś'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _moveContactToClients();
      return;
    }

    await _updateContact({
      'status': 'signed_contract',
      'note': _mergeNote('Wynik spotkania: spisana umowa.'),
    });
  }

  Future<void> _moveContactToClients() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await _supabase.from('clients').insert({
        'agent_id': user.id,
        'source_contact_id': contact.id,
        'client_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'correspondence_address': _addressController.text.trim(),
        'installation_address': _addressController.text.trim(),
        'product_name': '',
        'contract_signed_at': _dateOnly(DateTime.now()),
        'execution_method': 'finansowanie',
        'status': 'signed_contract',
      });

      await _supabase
          .from('contacts')
          .update({
            'status': 'signed_contract',
            'moved_to_client_at': DateTime.now().toIso8601String(),
            'note': _mergeNote(
              'Wynik spotkania: spisana umowa. Przeniesiono do W realizacji.',
            ),
          })
          .eq('id', contact.id);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kontakt przeniesiony do W realizacji.')),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _finishNotInterested() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Jaki powód?'),
        children: [
          for (final reason in _notInterestedReasons)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, reason),
              child: Text(reason),
            ),
        ],
      ),
    );

    if (reason == null || !mounted) return;
    final shouldArchive = reason == 'Cena' || reason == 'Beton';
    await _updateContact({
      'status': shouldArchive ? 'not_interested' : 'interested',
      'archived_at': shouldArchive ? DateTime.now().toIso8601String() : null,
      'note': _mergeNote(
        'Wynik spotkania: nie zainteresowany. Powód: $reason.',
      ),
    });
  }

  String _mergeNote(String _) {
    return _noteController.text.trim();
  }

  TimeOfDay _timeOfDayFromText(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 18, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 18,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  Future<void> _pickContactDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _contactDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _contactDate = picked);
  }

  Future<void> _pickContactTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _contactTime,
    );
    if (picked == null) return;
    setState(() => _contactTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusByValue(_status);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: status.color.withValues(alpha: 0.14),
                  foregroundColor: status.color,
                  child: Text(_initials(contact.contactName)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.trim().isEmpty
                            ? 'Bez nazwy'
                            : _nameController.text.trim(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.label,
                        style: TextStyle(
                          color: status.color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_phoneController.text.trim().isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _callPhone(context, _phoneController.text.trim()),
                      icon: const Icon(Icons.phone),
                      label: const Text('Zadzwoń'),
                    ),
                  ),
                if (_phoneController.text.trim().isNotEmpty &&
                    _addressController.text.trim().isNotEmpty)
                  const SizedBox(width: 10),
                if (_addressController.text.trim().isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openMap(context, _addressController.text.trim()),
                      icon: const Icon(Icons.home),
                      label: const Text('Nawiguj'),
                    ),
                  ),
              ],
            ),
            if (_status == 'scheduled_meeting' ||
                _status == 'meeting_active' ||
                _status == 'postponed') ...[
              const SizedBox(height: 12),
              _MeetingActionPanel(
                status: _status,
                onStart: _startMeeting,
                onFinish: _finishMeeting,
                onPostpone: _postponeMeeting,
                onArchive: () => _updateContact({
                  'archived_at': DateTime.now().toIso8601String(),
                  'note': _mergeNote(
                    'Kontakt zamknięty i przeniesiony do archiwum.',
                  ),
                }),
              ),
            ],
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Dane kontaktu'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nr telefonu'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Adres'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final status in _contactStatuses)
                  DropdownMenuItem(
                    value: status.value,
                    child: Text(status.label),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _status = value);
              },
            ),
            if (_status == 'scheduled_meeting') ...[
              const SizedBox(height: 12),
              _MeetingFields(
                date: _contactDate,
                time: _contactTime,
                quality: _contactQuality,
                onPickDate: _pickContactDate,
                onPickTime: _pickContactTime,
                onQualityChanged: (value) {
                  setState(() => _contactQuality = value);
                },
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Uwagi / notatki'),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isSaving ? 'Zapisuję...' : 'Zapisz zmiany'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: appTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MeetingActionPanel extends StatelessWidget {
  const _MeetingActionPanel({
    required this.status,
    required this.onStart,
    required this.onFinish,
    required this.onPostpone,
    required this.onArchive,
  });

  final String status;
  final VoidCallback onStart;
  final VoidCallback onFinish;
  final VoidCallback onPostpone;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'meeting_active';
    final title = isActive ? 'Spotkanie trwa...' : 'Co robimy ze spotkaniem?';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appSurfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isActive
                    ? Icons.timer_outlined
                    : Icons.event_available_outlined,
                color: appBrand,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isActive)
            FilledButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Zakończ spotkanie'),
            )
          else
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start spotkania'),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPostpone,
                  icon: const Icon(Icons.update_outlined),
                  label: const Text('Przełóż'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onArchive,
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archiwum'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeetingResultButton extends StatelessWidget {
  const _MeetingResultButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.24)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatsData {
  const _StatsData({
    required this.contacts,
    required this.clients,
    required this.leadSessions,
  });

  final List<Contact> contacts;
  final List<Client> clients;
  final List<Map<String, dynamic>> leadSessions;
}

class _StatsTileData {
  const _StatsTileData({
    required this.id,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _StatsRange {
  const _StatsRange(this.value, this.label);

  final String value;
  final String label;
}

const _statsRanges = [
  _StatsRange('all', 'Łącznie'),
  _StatsRange('year', 'Rok'),
  _StatsRange('month', 'Miesiąc'),
  _StatsRange('week', 'Tydzień'),
  _StatsRange('day', 'Dzień'),
];

class _StatisticsPageState extends State<StatisticsPage> {
  late Future<_StatsData> _statsFuture;
  String _range = 'all';

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStatsData();
  }

  Future<_StatsData> _fetchStatsData() async {
    final results = await Future.wait([
      _supabase
          .from('contacts')
          .select()
          .isFilter('archived_at', null)
          .isFilter('moved_to_client_at', null),
      _supabase.from('clients').select().isFilter('archived_at', null),
      _fetchLeadSessionsForStats(),
    ]);

    final contacts = results[0]
        .map((item) => Contact.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    final clients = results[1]
        .map((item) => Client.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return _StatsData(
      contacts: contacts,
      clients: clients,
      leadSessions: results[2]
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }

  Future<List<dynamic>> _fetchLeadSessionsForStats() async {
    try {
      final remoteSessions = await _supabase.from('lead_sessions').select();
      return [...remoteSessions, ..._localLeadSessions];
    } catch (_) {
      return List<Map<String, dynamic>>.from(_localLeadSessions);
    }
  }

  void _reload() {
    setState(() => _statsFuture = _fetchStatsData());
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      child: FutureBuilder<_StatsData>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              text: 'Nie udało się pobrać statystyk.',
              detail: snapshot.error.toString(),
            );
          }

          final data =
              snapshot.data ??
              const _StatsData(contacts: [], clients: [], leadSessions: []);
          final contacts = data.contacts
              .where((contact) => _isContactInRange(contact, _range))
              .toList();
          final clients = data.clients
              .where((client) => _isClientInRange(client, _range))
              .toList();
          final signedClients = clients
              .where((client) => client.status == 'signed_contract')
              .length;
          final leadSessions = data.leadSessions
              .where((session) => _isSessionInRange(session, _range))
              .toList();
          final totalLeadSeconds = leadSessions.fold<int>(
            0,
            (sum, session) =>
                sum + (session['work_seconds'] as num? ?? 0).toInt(),
          );

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _StatsRangeSelector(
                  currentRange: _range,
                  onChanged: (range) => setState(() => _range = range),
                ),
                const SizedBox(height: 14),
                _StatsGrid(
                  tiles: [
                    _StatsTileData(
                      id: 'contacts',
                      title: 'Dodane kontakty',
                      value: contacts.length.toString(),
                      subtitle: 'Aktywne kontakty',
                      icon: Icons.groups,
                      color: appBrand,
                    ),
                    _StatsTileData(
                      id: 'clients',
                      title: 'W realizacji',
                      value: clients.length.toString(),
                      subtitle: 'Aktywne sprawy',
                      icon: Icons.precision_manufacturing,
                      color: appInfo,
                    ),
                    _StatsTileData(
                      id: 'signed_clients',
                      title: 'Spisani klienci',
                      value: signedClients.toString(),
                      subtitle: 'Spisana umowa',
                      icon: Icons.assignment_turned_in,
                      color: const Color(0xFF8A6F20),
                    ),
                    _StatsTileData(
                      id: 'lead_time',
                      title: 'Czas leadowania',
                      value: _formatDuration(
                        Duration(seconds: totalLeadSeconds),
                      ),
                      subtitle: 'Łącznie',
                      icon: Icons.timer_outlined,
                      color: appMuted,
                    ),
                    _StatsTileData(
                      id: 'lead_sessions',
                      title: 'Sesje leadowania',
                      value: leadSessions.length.toString(),
                      subtitle: 'Ile razy agent leadował',
                      icon: Icons.route_outlined,
                      color: appDanger,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isContactInRange(Contact contact, String range) {
    final date = contact.contactDate ?? contact.contactNotification;
    if (range == 'all' || date == null) return range == 'all';
    return _isDateInRange(date, range);
  }

  bool _isClientInRange(Client client, String range) {
    final date = client.contractSignedAt;
    if (range == 'all' || date == null) return range == 'all';
    return _isDateInRange(date, range);
  }

  bool _isSessionInRange(Map<String, dynamic> session, String range) {
    final date = DateTime.tryParse(session['session_date']?.toString() ?? '');
    if (range == 'all' || date == null) return range == 'all';
    return _isDateInRange(date, range);
  }

  bool _isDateInRange(DateTime date, String range) {
    final now = DateTime.now();
    return switch (range) {
      'day' => _isSameDay(date, now),
      'week' => _weekStart(date).isAtSameMomentAs(_weekStart(now)),
      'month' => date.year == now.year && date.month == now.month,
      'year' => date.year == now.year,
      _ => true,
    };
  }

  DateTime _weekStart(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}

class _StatsTile extends StatelessWidget {
  const _StatsTile({required this.tile, required this.onTap});

  final _StatsTileData tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: appSurface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: appBorder),
              boxShadow: [
                BoxShadow(
                  color: appTextPrimary.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(tile.icon, color: tile.color, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tile.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  tile.value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tile.subtitle,
                  style: const TextStyle(
                    color: appTextSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRangeSelector extends StatelessWidget {
  const _StatsRangeSelector({
    required this.currentRange,
    required this.onChanged,
  });

  final String currentRange;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final range in _statsRanges)
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: appTextPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => onChanged(range.value),
              child: Text(
                range.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: currentRange == range.value
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.tiles});

  final List<_StatsTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.18,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final tile in tiles) _StatsTile(tile: tile, onTap: () {}),
      ],
    );
  }
}

class ArchivedContactsPage extends StatefulWidget {
  const ArchivedContactsPage({super.key});

  @override
  State<ArchivedContactsPage> createState() => _ArchivedContactsPageState();
}

class _ArchivedContactsPageState extends State<ArchivedContactsPage> {
  late Future<List<Contact>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _contactsFuture = _fetchArchivedContacts();
  }

  Future<List<Contact>> _fetchArchivedContacts() async {
    final data = await _supabase
        .from('contacts')
        .select()
        .not('archived_at', 'is', null)
        .isFilter('moved_to_client_at', null);

    return (data as List)
        .map((item) => Contact.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  void _reload() {
    setState(() => _contactsFuture = _fetchArchivedContacts());
  }

  Future<void> _restoreContact(Contact contact) async {
    await _supabase
        .from('contacts')
        .update({'archived_at': null})
        .eq('id', contact.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          tooltip: 'Wróć',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Row(
          children: [
            Icon(Icons.archive_outlined, color: appBrand, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Archiwum kontaktów',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: appBorder),
        ),
      ),
      body: _PageShell(
        child: FutureBuilder<List<Contact>>(
          future: _contactsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _EmptyState(
                icon: Icons.error_outline,
                text: 'Nie udało się pobrać archiwum.',
                detail: snapshot.error.toString(),
              );
            }

            final contacts = snapshot.data ?? [];
            if (contacts.isEmpty) {
              return const _EmptyState(
                icon: Icons.archive_outlined,
                text: 'Archiwum jest puste.',
                detail: 'Zarchiwizowane kontakty pojawią się tutaj.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 28),
                itemCount: contacts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return _ArchivedContactTile(
                    contact: contact,
                    onRestore: () => _restoreContact(contact),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ArchivedContactTile extends StatelessWidget {
  const _ArchivedContactTile({required this.contact, required this.onRestore});

  final Contact contact;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    final status = _statusByValue(contact.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: status.color.withValues(alpha: 0.14),
            foregroundColor: status.color,
            child: Text(_initials(contact.contactName)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.contactName.isEmpty
                      ? 'Bez nazwy'
                      : contact.contactName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    status.label,
                    if (contact.phone.isNotEmpty) contact.phone,
                    if (contact.address.isNotEmpty) contact.address,
                  ].join(' | '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: appTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: onRestore,
            icon: const Icon(Icons.restore_outlined, size: 18),
            label: const Text('Przywróć'),
          ),
        ],
      ),
    );
  }
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _meetingReminders = false;
  bool _phoneReminders = true;
  bool _visitReminders = true;
  bool _inAppNotifications = true;
  bool _pushNotifications = false;
  bool _emailNotifications = false;
  bool _salesMeetingNotifications = true;
  bool _dashboardPersonalization = true;
  bool _dashboardVisibleSections = true;
  bool _dashboardSectionOrder = true;
  bool _emailReports = false;
  bool _weeklyReports = false;
  bool _monthlyReports = false;
  bool _autoRecordMeetings = true;
  int _defaultLeadGoal = 9;

  void _showOnboardingPreview() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _OnboardingPreviewDialog(),
    );
  }

  void _openArchivedContacts() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const ArchivedContactsPage();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(opacity: curvedAnimation, child: child),
          );
        },
      ),
    );
  }

  void _openUnprocessedMeetings() {
    _openSettingsCategory(
      title: 'Nieprzerobione spotkania',
      icon: Icons.pending_actions_outlined,
      children: const [_UnprocessedMeetingsList()],
    );
  }

  void _openSettingsCategory({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return _SettingsDetailPage(
            title: title,
            icon: icon,
            children: children,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(opacity: curvedAnimation, child: child),
          );
        },
      ),
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Zdjęcie profilowe',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _pickAvatarImage();
                },
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Dodaj zdjęcie'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAvatarImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 85,
    );
    if (image == null) return;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_avatarPathPreferenceKey, image.path);
    _avatarPathNotifier.value = image.path;
  }

  Future<void> _editDefaultLeadGoal() async {
    final controller = TextEditingController(text: _defaultLeadGoal.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cel domyślny'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Liczba spotkań'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text.trim())),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (value == null || value <= 0) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_defaultLeadGoalPreferenceKey, value);
    _defaultLeadGoalNotifier.value = value;
    setState(() => _defaultLeadGoal = value);
  }

  void _showAiInstructionPlaceholder() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Instrukcja dla agenta AI'),
        content: const Text(
          'To będzie miejsce na instrukcję, według której aplikacja analizuje lokalne nagrania i wyciąga konkluzje dla agenta.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final email = user?.email ?? '';
    final name = _userDisplayName(user);

    return _PageShell(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 22),
        children: [
          ValueListenableBuilder<String?>(
            valueListenable: _avatarPathNotifier,
            builder: (context, avatarPath, _) {
              return _AccountHeader(
                name: name,
                email: email,
                initials: _userInitials(user),
                avatarPath: avatarPath,
                onAvatarTap: _showAvatarOptions,
              );
            },
          ),
          const SizedBox(height: 14),
          _SettingsCategoryTile(
            icon: Icons.person_outline,
            title: 'Konto',
            subtitle: 'Profil, e-mail, hasło i usunięcie konta',
            onTap: () => _openSettingsCategory(
              title: 'Konto',
              icon: Icons.person_outline,
              children: [
                const _SettingsRow(
                  icon: Icons.badge_outlined,
                  label: 'Imię i nazwisko',
                  value: 'Do uzupełnienia',
                ),
                _SettingsRow(
                  icon: Icons.alternate_email_outlined,
                  label: 'Adres e-mail',
                  value: email.isEmpty ? 'Brak e-maila' : email,
                ),
                const _SettingsRow(
                  icon: Icons.phone_outlined,
                  label: 'Numer telefonu',
                  value: 'Opcjonalny',
                ),
                const _SettingsRow(
                  icon: Icons.solar_power_outlined,
                  label: 'Branża sprzedażowa',
                  value: 'OZE / sprzedaż bezpośrednia',
                ),
                _SettingsAction(
                  icon: Icons.archive_outlined,
                  label: 'Archiwum kontaktów',
                  onTap: _openArchivedContacts,
                ),
                _SettingsAction(
                  icon: Icons.pending_actions_outlined,
                  label: 'Nieprzerobione spotkania',
                  onTap: _openUnprocessedMeetings,
                ),
                _SettingsAction(
                  icon: Icons.lock_reset_outlined,
                  label: 'Zmiana hasła',
                  onTap: () {},
                ),
                _SettingsAction(
                  icon: Icons.logout_outlined,
                  label: 'Wyloguj',
                  onTap: () => _supabase.auth.signOut(),
                ),
                _SettingsAction(
                  icon: Icons.delete_forever_outlined,
                  label: 'Usuń konto',
                  destructive: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
          _SettingsCategoryTile(
            icon: Icons.notifications_none,
            title: 'Powiadomienia',
            subtitle: 'Kanały, przypomnienia i push',
            onTap: () => _openSettingsCategory(
              title: 'Powiadomienia',
              icon: Icons.notifications_none,
              children: [
                _SettingsSwitch(
                  icon: Icons.app_shortcut_outlined,
                  label: 'Powiadomienia w aplikacji',
                  value: _inAppNotifications,
                  onChanged: (value) =>
                      setState(() => _inAppNotifications = value),
                ),
                _SettingsSwitch(
                  icon: Icons.notifications_active_outlined,
                  label: 'Powiadomienia push',
                  value: _pushNotifications,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                ),
                _SettingsSwitch(
                  icon: Icons.alternate_email_outlined,
                  label: 'Powiadomienia e-mail',
                  value: _emailNotifications,
                  onChanged: (value) =>
                      setState(() => _emailNotifications = value),
                ),
                _SettingsSwitch(
                  icon: Icons.event_available_outlined,
                  label: 'Przypomnienia o spotkaniach',
                  value: _meetingReminders,
                  onChanged: (value) =>
                      setState(() => _meetingReminders = value),
                ),
                _SettingsSwitch(
                  icon: Icons.call_outlined,
                  label: 'Przypomnienia o klientach do telefonu',
                  value: _phoneReminders,
                  onChanged: (value) => setState(() => _phoneReminders = value),
                ),
                _SettingsSwitch(
                  icon: Icons.place_outlined,
                  label: 'Przypomnienia o klientach do podjechania',
                  value: _visitReminders,
                  onChanged: (value) => setState(() => _visitReminders = value),
                ),
                _SettingsSwitch(
                  icon: Icons.notifications_outlined,
                  label: 'Powiadomienia push włączone/wyłączone',
                  value: _pushNotifications,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                ),
              ],
            ),
          ),
          _SettingsCategoryTile(
            icon: Icons.directions_walk,
            title: 'System pracy - leadowanie',
            subtitle: 'Tydzień pracy, cel i status kontaktu',
            onTap: () => _openSettingsCategory(
              title: 'System pracy - leadowanie',
              icon: Icons.directions_walk,
              children: [
                const _SettingsRow(
                  icon: Icons.first_page_outlined,
                  label: 'Początek tygodnia pracy',
                  value: 'Poniedziałek',
                ),
                const _SettingsRow(
                  icon: Icons.last_page_outlined,
                  label: 'Koniec tygodnia pracy',
                  value: 'Piątek',
                ),
                _SettingsRow(
                  icon: Icons.flag_outlined,
                  label: 'Cel leadowania',
                  value: '$_defaultLeadGoal spotkań',
                ),
                _SettingsAction(
                  icon: Icons.flag_circle_outlined,
                  label: 'Ustaw cel leadowania',
                  onTap: _editDefaultLeadGoal,
                ),
                const _SettingsRow(
                  icon: Icons.sync_alt_outlined,
                  label: 'Cykl pracy',
                  value: 'Mieszany',
                ),
                const _SettingsRow(
                  icon: Icons.label_outline,
                  label: 'Domyślny status nowego kontaktu',
                  value: 'Umówione spotkanie',
                ),
                _SettingsAction(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Pokaż onboarding',
                  onTap: _showOnboardingPreview,
                ),
              ],
            ),
          ),
          _SettingsCategoryTile(
            icon: Icons.handshake_outlined,
            title: 'Sprzedaż',
            subtitle: 'Produkty, godziny spotkań i tryb sprzedaży',
            onTap: () => _openSettingsCategory(
              title: 'Sprzedaż',
              icon: Icons.handshake_outlined,
              children: [
                const _SettingsRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Aktywne produkty',
                  value: 'PV + ME, ME, UPSELL...',
                ),
                const _SettingsRow(
                  icon: Icons.timer_outlined,
                  label: 'Średni czas trwania spotkania sprzedażowego',
                  value: 'Do ustalenia',
                ),
                const _SettingsRow(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Początek dnia sprzedażowego',
                  value: '12:00',
                ),
                const _SettingsRow(
                  icon: Icons.nights_stay_outlined,
                  label: 'Koniec dnia sprzedażowego',
                  value: '18:00',
                ),
                _SettingsSwitch(
                  icon: Icons.mic_none_outlined,
                  label: 'Automatyczne nagrywanie spotkań',
                  value: _autoRecordMeetings,
                  onChanged: (value) =>
                      setState(() => _autoRecordMeetings = value),
                ),
                _SettingsSwitch(
                  icon: Icons.notifications_paused_outlined,
                  label: 'Powiadomienia podczas spotkań sprzedażowych',
                  value: _salesMeetingNotifications,
                  onChanged: (value) =>
                      setState(() => _salesMeetingNotifications = value),
                ),
                _SettingsAction(
                  icon: Icons.pending_actions_outlined,
                  label: 'Nieprzerobione spotkania',
                  onTap: _openUnprocessedMeetings,
                ),
              ],
            ),
          ),
          _SettingsCategoryTile(
            icon: Icons.psychology_alt_outlined,
            title: 'Mechanika 1.2',
            subtitle: 'Agent AI w tle, statusy i podsumowania',
            onTap: () => _openSettingsCategory(
              title: 'Mechanika 1.2',
              icon: Icons.psychology_alt_outlined,
              children: [
                const _SettingsRow(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Agent AI',
                  value: 'Ukryty mechanizm w tle',
                ),
                const _SettingsRow(
                  icon: Icons.insights_outlined,
                  label: 'Analiza nagrań',
                  value: 'Konkluzje zapisują się na stałe',
                ),
                const _SettingsRow(
                  icon: Icons.route_outlined,
                  label: 'Cykl pracy',
                  value: 'Leadowanie + dzień sprzedażowy',
                ),
                const _SettingsRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Produkty',
                  value: 'Edytowalne w ustawieniach',
                ),
                _SettingsAction(
                  icon: Icons.description_outlined,
                  label: 'Instrukcja dla agenta AI',
                  onTap: _showAiInstructionPlaceholder,
                ),
              ],
            ),
          ),
          _SettingsCategoryTile(
            icon: Icons.dashboard_customize_outlined,
            title: 'Dashboard',
            subtitle: 'Widoczność i kolejność sekcji',
            onTap: () => _openSettingsCategory(
              title: 'Dashboard',
              icon: Icons.dashboard_customize_outlined,
              children: [
                _SettingsSwitch(
                  icon: Icons.tune_outlined,
                  label: 'Personalizacja ekranu głównego',
                  value: _dashboardPersonalization,
                  onChanged: (value) =>
                      setState(() => _dashboardPersonalization = value),
                ),
                _SettingsSwitch(
                  icon: Icons.visibility_outlined,
                  label: 'Wybór widocznych sekcji',
                  value: _dashboardVisibleSections,
                  onChanged: (value) =>
                      setState(() => _dashboardVisibleSections = value),
                ),
                _SettingsSwitch(
                  icon: Icons.reorder_outlined,
                  label: 'Kolejność sekcji',
                  value: _dashboardSectionOrder,
                  onChanged: (value) =>
                      setState(() => _dashboardSectionOrder = value),
                ),
              ],
            ),
          ),
          _SettingsCategoryTile(
            icon: Icons.summarize_outlined,
            title: 'Raporty',
            subtitle: 'E-mail, raporty tygodniowe i miesięczne',
            onTap: () => _openSettingsCategory(
              title: 'Raporty',
              icon: Icons.summarize_outlined,
              children: [
                _SettingsRow(
                  icon: Icons.alternate_email_outlined,
                  label: 'Adres e-mail do raportów',
                  value: email.isEmpty ? 'Do uzupełnienia' : email,
                ),
                _SettingsSwitch(
                  icon: Icons.send_outlined,
                  label: 'Wysyłka raportów e-mail',
                  value: _emailReports,
                  onChanged: (value) => setState(() => _emailReports = value),
                ),
                _SettingsSwitch(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Raporty tygodniowe (Premium)',
                  value: _weeklyReports,
                  onChanged: (value) => setState(() => _weeklyReports = value),
                ),
                _SettingsSwitch(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Raporty miesięczne (Premium)',
                  value: _monthlyReports,
                  onChanged: (value) => setState(() => _monthlyReports = value),
                ),
              ],
            ),
          ),
          _SettingsCategoryTile(
            icon: Icons.palette_outlined,
            title: 'Wygląd aplikacji',
            subtitle: 'Motyw i kolorystyka',
            onTap: () => _openSettingsCategory(
              title: 'Wygląd aplikacji',
              icon: Icons.palette_outlined,
              children: const [
                _SettingsRow(
                  icon: Icons.light_mode_outlined,
                  label: 'Motyw jasny',
                  value: 'Włączony',
                ),
                _SettingsRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'Motyw ciemny',
                  value: 'Wyłączony',
                ),
                _SettingsRow(
                  icon: Icons.brightness_auto_outlined,
                  label: 'Motyw systemowy',
                  value: 'Wyłączony',
                ),
                _SettingsRow(
                  icon: Icons.format_paint_outlined,
                  label: 'Wybór kolorystyki',
                  value: 'Doorka',
                ),
              ],
            ),
          ),
          _SettingsCategoryTile(
            icon: Icons.help_outline,
            title: 'Pomoc i informacje',
            subtitle: 'FAQ, kontakt, regulamin i wersja aplikacji',
            onTap: () => _openSettingsCategory(
              title: 'Pomoc i informacje',
              icon: Icons.help_outline,
              children: const [
                _SettingsRow(
                  icon: Icons.quiz_outlined,
                  label: 'FAQ',
                  value: 'Otwórz',
                ),
                _SettingsRow(
                  icon: Icons.support_agent_outlined,
                  label: 'Centrum pomocy',
                  value: 'Otwórz',
                ),
                _SettingsRow(
                  icon: Icons.mail_outline,
                  label: 'Kontakt',
                  value: 'Otwórz',
                ),
                _SettingsRow(
                  icon: Icons.bug_report_outlined,
                  label: 'Zgłoś problem',
                  value: 'Otwórz',
                ),
                _SettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Polityka prywatności',
                  value: 'Otwórz',
                ),
                _SettingsRow(
                  icon: Icons.gavel_outlined,
                  label: 'Regulamin',
                  value: 'Otwórz',
                ),
                _SettingsRow(
                  icon: Icons.info_outline,
                  label: 'Wersja aplikacji',
                  value: '0.1.0',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({
    required this.name,
    required this.email,
    required this.initials,
    required this.avatarPath,
    required this.onAvatarTap,
  });

  final String name;
  final String email;
  final String initials;
  final String? avatarPath;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorder),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onAvatarTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: appBrandSoft,
                  foregroundColor: appBrand,
                  child: avatarPath == null || avatarPath!.isEmpty
                      ? Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : ClipOval(child: _AvatarImage(path: avatarPath!)),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: appTextPrimary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    color: appSurface,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? 'Brak adresu e-mail' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: appTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCategoryTile extends StatelessWidget {
  const _SettingsCategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: appSurface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: appBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: appBrandSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: appBrand, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: appTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: appTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right, color: appTextSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsDetailPage extends StatelessWidget {
  const _SettingsDetailPage({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          tooltip: 'Wróć',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Row(
          children: [
            Icon(icon, color: appBrand, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: appBorder),
        ),
      ),
      body: _PageShell(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 22),
          children: [
            Container(
              decoration: BoxDecoration(
                color: appSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: appBorder),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index != children.length - 1)
                      const Divider(height: 1, color: appBorder),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPreviewDialog extends StatefulWidget {
  const _OnboardingPreviewDialog();

  @override
  State<_OnboardingPreviewDialog> createState() =>
      _OnboardingPreviewDialogState();
}

class _OnboardingPreviewDialogState extends State<_OnboardingPreviewDialog> {
  int _step = 0;

  static const _titles = [
    'Ustaw rytm pracy',
    'Wybierz dni leadowania',
    'Ustaw cel leadowania',
  ];

  void _next() {
    if (_step == _titles.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step++);
  }

  void _previous() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: screenWidth > 520 ? 460 : 420),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: appBackground,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                  color: appTextPrimary,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pierwsza konfiguracja',
                              style: TextStyle(
                                color: appBrandSoft,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Text(
                                _titles[_step],
                                key: ValueKey(_step),
                                style: const TextStyle(
                                  color: appSurface,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Zamknij',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: appSurface),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _OnboardingProgress(step: _step, total: _titles.length),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, animation) {
                          final offset =
                              Tween<Offset>(
                                begin: const Offset(0.08, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: _OnboardingStepContent(
                          key: ValueKey(_step),
                          step: _step,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previous,
                              child: Text(_step == 0 ? 'Zamknij' : 'Wstecz'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: _next,
                              child: Text(
                                _step == _titles.length - 1
                                    ? 'Zobacz aplikację'
                                    : 'Dalej',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < total; index++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 5,
              decoration: BoxDecoration(
                color: index <= step ? appSuccess : appBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          if (index != total - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _OnboardingStepContent extends StatelessWidget {
  const _OnboardingStepContent({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 0:
        return const _OnboardingChoiceGrid(
          title: 'Jaki typ dnia chcesz skonfigurować jako pierwszy?',
          choices: [
            _OnboardingChoice(Icons.directions_walk, 'Umawianie spotkań'),
            _OnboardingChoice(Icons.handshake_outlined, 'Spotkania'),
            _OnboardingChoice(Icons.event_note_outlined, 'Organizacja'),
            _OnboardingChoice(Icons.self_improvement_outlined, 'Odpoczynek'),
          ],
        );
      case 1:
        return const _OnboardingChoiceGrid(
          title: 'W które dni aplikacja ma domyślnie pokazywać leadowanie?',
          choices: [
            _OnboardingChoice(Icons.looks_one_outlined, 'Poniedziałek'),
            _OnboardingChoice(Icons.looks_two_outlined, 'Wtorek'),
            _OnboardingChoice(Icons.looks_3_outlined, 'Środa'),
            _OnboardingChoice(Icons.more_horiz, 'Więcej później'),
          ],
        );
      default:
        return Column(
          key: const ValueKey('goal'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jaki cel ma podpowiadać Dashboard przed startem leadowania?',
              style: TextStyle(
                color: appTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: const [
                Expanded(
                  child: _GoalPreviewTile(value: '5', label: 'spokojnie'),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _GoalPreviewTile(value: '9', label: 'mocny dzień'),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _GoalPreviewTile(value: '+', label: 'własny'),
                ),
              ],
            ),
          ],
        );
    }
  }
}

class _OnboardingChoice {
  const _OnboardingChoice(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _OnboardingChoiceGrid extends StatelessWidget {
  const _OnboardingChoiceGrid({required this.title, required this.choices});

  final String title;
  final List<_OnboardingChoice> choices;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(title),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: appTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: choices.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
          ),
          itemBuilder: (context, index) {
            final choice = choices[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: appSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: index == 0 ? appSuccess : appBorder,
                  width: index == 0 ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(choice.icon, color: appBrand, size: 22),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      choice.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: appTextPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GoalPreviewTile extends StatelessWidget {
  const _GoalPreviewTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: appTextPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: appTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnprocessedMeetingsList extends StatefulWidget {
  const _UnprocessedMeetingsList();

  @override
  State<_UnprocessedMeetingsList> createState() =>
      _UnprocessedMeetingsListState();
}

class _UnprocessedMeetingsListState extends State<_UnprocessedMeetingsList> {
  late Future<List<Contact>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _meetingsFuture = _fetchMeetings();
  }

  Future<List<Contact>> _fetchMeetings() async {
    final data = await _supabase
        .from('contacts')
        .select()
        .isFilter('archived_at', null)
        .isFilter('moved_to_client_at', null);

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return (data as List)
        .map((item) => Contact.fromMap(Map<String, dynamic>.from(item)))
        .where((contact) {
          if (contact.status == 'meeting_active' ||
              contact.status == 'postponed') {
            return true;
          }

          if (contact.status != 'scheduled_meeting' ||
              contact.contactDate == null) {
            return false;
          }

          final meetingDay = DateTime(
            contact.contactDate!.year,
            contact.contactDate!.month,
            contact.contactDate!.day,
          );
          return meetingDay.isBefore(todayOnly);
        })
        .toList()
      ..sort((a, b) {
        final aDate = a.contactDate ?? DateTime(1900);
        final bDate = b.contactDate ?? DateTime(1900);
        final dateCompare = bDate.compareTo(aDate);
        if (dateCompare != 0) return dateCompare;
        return b.contactTime.compareTo(a.contactTime);
      });
  }

  void _reload() {
    setState(() => _meetingsFuture = _fetchMeetings());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Contact>>(
      future: _meetingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _SettingsInfoCard(
            icon: Icons.error_outline,
            title: 'Nie udało się pobrać spotkań',
            text: snapshot.error.toString(),
          );
        }

        final meetings = snapshot.data ?? [];
        if (meetings.isEmpty) {
          return const _SettingsInfoCard(
            icon: Icons.check_circle_outline,
            title: 'Brak nieprzerobionych spotkań',
            text: 'Wszystkie zapisane spotkania są domknięte albo aktualne.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingsInfoCard(
              icon: Icons.pending_actions_outlined,
              title: 'Do przerobienia',
              text:
                  'Masz ${meetings.length} spotkań, które wymagają rozliczenia albo decyzji.',
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < meetings.length; index++) ...[
              if (index > 0) const SizedBox(height: 8),
              _UnprocessedMeetingTile(
                contact: meetings[index],
                onChanged: _reload,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SettingsInfoCard extends StatelessWidget {
  const _SettingsInfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurface,
        border: Border.all(color: appBorderStrong),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: appBrand, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: appTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(color: appTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnprocessedMeetingTile extends StatelessWidget {
  const _UnprocessedMeetingTile({
    required this.contact,
    required this.onChanged,
  });

  final Contact contact;
  final VoidCallback onChanged;

  String get _dateText {
    if (contact.contactDate == null) return 'Bez daty';
    return '${_shortDate(contact.contactDate!)} | ${_weekdayNameFull(contact.contactDate!)}';
  }

  String get _timeText {
    if (contact.contactTime.length >= 5) {
      return contact.contactTime.substring(0, 5);
    }
    return contact.contactTime.isEmpty ? '--:--' : contact.contactTime;
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusByValue(contact.status);
    final note = contact.note.trim();

    return Material(
      color: appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: appBorderStrong),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await showContactDetailsSheet(context, contact);
          onChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: status.color.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Text(
                      _timeText,
                      style: TextStyle(
                        color: status.color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      contact.contactName.isEmpty
                          ? 'Bez nazwy'
                          : contact.contactName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: appTextPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: status.color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$_dateText · ${status.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: appTextSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 6),
                const Divider(height: 1, color: appBorder),
                const SizedBox(height: 6),
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: appTextSecondary, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _SettingsBaseRow(
      icon: icon,
      label: label,
      trailing: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: appTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatefulWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<_SettingsSwitch> createState() => _SettingsSwitchState();
}

class _SettingsSwitchState extends State<_SettingsSwitch> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant _SettingsSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsBaseRow(
      icon: widget.icon,
      label: widget.label,
      trailing: Switch(
        value: _value,
        onChanged: (value) {
          setState(() => _value = value);
          widget.onChanged(value);
        },
        activeThumbColor: appBrand,
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? appDanger : appTextPrimary;
    return InkWell(
      onTap: onTap,
      child: _SettingsBaseRow(
        icon: icon,
        label: label,
        color: color,
        trailing: Icon(Icons.chevron_right, color: color),
      ),
    );
  }
}

class _SettingsBaseRow extends StatelessWidget {
  const _SettingsBaseRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.color = appTextPrimary,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}

class _PageShell extends StatelessWidget {
  const _PageShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: child,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text, this.detail});

  final IconData icon;
  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: appTextSecondary),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: appTextSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<bool?> showAddContactSheet(
  BuildContext context, {
  String initialStatus = 'scheduled_meeting',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AddContactSheet(initialStatus: initialStatus),
  );
}

class AddContactSheet extends StatefulWidget {
  const AddContactSheet({super.key, required this.initialStatus});

  final String initialStatus;

  @override
  State<AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<AddContactSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  late String _status;
  DateTime _contactDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _contactTime = const TimeOfDay(hour: 18, minute: 0);
  String? _contactQuality;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final phone = _phoneController.text.trim();
      if (phone.isNotEmpty && await _contactPhoneExists(user.id, phone)) {
        _showError('Kontakt z tym numerem telefonu juz istnieje.');
        return;
      }

      final payload = <String, dynamic>{
        'agent_id': user.id,
        'contact_name': _nameController.text.trim(),
        'phone': phone,
        'address': _addressController.text.trim(),
        'status': _status,
        'note': _noteController.text.trim(),
      };

      if (_status == 'scheduled_meeting') {
        payload.addAll({
          'contact_date': _dateOnly(_contactDate),
          'contact_time': _timeOnly(_contactTime),
          'meeting_time': _timeOnly(_contactTime),
          'contact_quality': _contactQuality,
        });
      }

      await _supabase.from('contacts').insert(payload);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kontakt został dodany.')));
    } on PostgrestException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Nie udało się dodać kontaktu.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _contactPhoneExists(String agentId, String phone) async {
    final normalizedPhone = _normalizePhone(phone);
    final data = await _supabase
        .from('contacts')
        .select('id, phone')
        .eq('agent_id', agentId)
        .isFilter('archived_at', null)
        .isFilter('moved_to_client_at', null);

    return (data as List).any((item) {
      final existingPhone = Map<String, dynamic>.from(
        item,
      )['phone']?.toString();
      return _normalizePhone(existingPhone ?? '') == normalizedPhone;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickContactDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _contactDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _contactDate = picked);
  }

  Future<void> _pickContactTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _contactTime,
    );
    if (picked == null) return;
    setState(() => _contactTime = picked);
  }

  String get _formTitle {
    return switch (_status) {
      'scheduled_meeting' => 'Umów spotkanie',
      'contact' => 'Dodaj kontakt',
      'postponed' => 'Przełożone',
      _ => 'Dodaj kontakt',
    };
  }

  String get _formHint {
    return switch (_status) {
      'scheduled_meeting' => 'Minimum: dane kontaktu, adres i dzień.',
      'contact' => 'Zapisz dane kontaktu, do którego chcesz wrócić.',
      _ => 'Dodaj dane kontaktu.',
    };
  }

  bool get _showStatusPicker => false;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  _ContactStatusPill(status: _statusByValue(_status)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formHint,
                style: const TextStyle(
                  color: appTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Dane kontaktu'),
                validator: (value) {
                  if (_status == 'scheduled_meeting' &&
                      (value ?? '').trim().isEmpty) {
                    return 'Wpisz dane kontaktu.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nr telefonu'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adres'),
              ),
              if (_showStatusPicker) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    for (final status in _contactStatuses)
                      DropdownMenuItem(
                        value: status.value,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                  },
                ),
              ],
              if (_status == 'scheduled_meeting') ...[
                const SizedBox(height: 12),
                _MeetingFields(
                  date: _contactDate,
                  time: _contactTime,
                  quality: _contactQuality,
                  onPickDate: _pickContactDate,
                  onPickTime: _pickContactTime,
                  onQualityChanged: (value) {
                    setState(() => _contactQuality = value);
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Uwagi / notatki'),
                validator: (value) {
                  final phone = _phoneController.text.trim();
                  final address = _addressController.text.trim();
                  final note = (value ?? '').trim();
                  final name = _nameController.text.trim();
                  if (_status == 'scheduled_meeting' && address.isEmpty) {
                    return 'Umówione spotkanie musi mieć adres.';
                  }
                  if (_status == 'contact' &&
                      name.isEmpty &&
                      phone.isEmpty &&
                      address.isEmpty &&
                      note.isEmpty) {
                    return 'Dodaj dane kontaktu, telefon, adres albo notatkę.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(
                  _isSaving
                      ? (_status == 'scheduled_meeting'
                            ? 'Umawiam...'
                            : 'Zapisuję...')
                      : (_status == 'scheduled_meeting'
                            ? 'Umów spotkanie'
                            : 'Dodaj kontakt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingFields extends StatelessWidget {
  const _MeetingFields({
    required this.date,
    required this.time,
    required this.quality,
    required this.onPickDate,
    required this.onPickTime,
    required this.onQualityChanged,
  });

  final DateTime date;
  final TimeOfDay time;
  final String? quality;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final ValueChanged<String?> onQualityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('${_shortDate(date)} (${_weekdayName(date)})'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickTime,
                icon: const Icon(Icons.schedule),
                label: Text(_timeOnly(time)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: quality,
          decoration: const InputDecoration(labelText: 'Jakość'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Brak')),
            for (final item in _qualities)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: onQualityChanged,
        ),
      ],
    );
  }
}
