import 'dart:async';
import 'dart:convert';
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
final ValueNotifier<int> _authRefreshNotifier = ValueNotifier<int>(0);
final ValueNotifier<int> _unprocessedMeetingsNotifier = ValueNotifier<int>(0);
final ValueNotifier<List<ContactStatus>> _customContactStatusesNotifier =
    ValueNotifier<List<ContactStatus>>([]);
const _avatarPathPreferenceKey = 'doorka.avatar_path';
const _defaultLeadGoalPreferenceKey = 'doorka.default_lead_goal';
const _customContactStatusesPreferenceKey = 'doorka.custom_contact_statuses';
const _rememberLoginPreferenceKey = 'doorka.remember_login';
const _rememberedEmailPreferenceKey = 'doorka.remembered_email';
const _rememberedPasswordPreferenceKey = 'doorka.remembered_password';
const _leadDayStartedAtPreferenceKey = 'doorka.lead_day_started_at';
const _leadDayBreakStartedAtPreferenceKey = 'doorka.lead_day_break_started_at';
const _leadDayBreakSecondsPreferenceKey = 'doorka.lead_day_break_seconds';
const _manualRefreshTimeout = Duration(seconds: 20);

void _ignoreManualRefreshError(Object error) {}

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
  late final VoidCallback _authRefreshListener;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _session = _supabase.auth.currentSession;
    _authRefreshListener = _refreshAuthState;
    _authRefreshNotifier.addListener(_authRefreshListener);
    _syncCurrentProfile();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      setState(() {
        _session = state.session;
      });
      _syncCurrentProfile();
    });
  }

  @override
  void dispose() {
    _authRefreshNotifier.removeListener(_authRefreshListener);
    _authSubscription.cancel();
    super.dispose();
  }

  void _refreshAuthState() {
    if (!mounted) return;
    setState(() {
      _session = _supabase.auth.currentSession;
    });
    _syncCurrentProfile();
  }

  Future<void> _syncCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    final email = user.email?.toLowerCase();
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final fullName = metadata['full_name'] ?? metadata['name'] ?? email;
    final avatarUrl = metadata['avatar_url'] ?? metadata['picture'];

    try {
      await _supabase
          .from('profiles')
          .upsert({
            'id': user.id,
            'email': email,
            'full_name': fullName,
            'avatar_path': avatarUrl,
            'role': email == _adminEmail ? 'admin' : 'agent',
          })
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Profil nie może blokować wejścia do aplikacji.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const AuthScreen();
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
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  int _authStep = 0;
  int _previousAuthStep = 0;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    _resetEmailController.dispose();
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

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldRemember = prefs.getBool(_rememberLoginPreferenceKey) ?? false;
    if (!mounted || !shouldRemember) return;

    setState(() {
      _rememberMe = true;
      _emailController.text =
          prefs.getString(_rememberedEmailPreferenceKey) ?? '';
      _passwordController.text =
          prefs.getString(_rememberedPasswordPreferenceKey) ?? '';
    });
  }

  Future<void> _saveRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberLoginPreferenceKey, _rememberMe);

    if (_rememberMe) {
      await prefs.setString(
        _rememberedEmailPreferenceKey,
        _emailController.text.trim(),
      );
      await prefs.setString(
        _rememberedPasswordPreferenceKey,
        _passwordController.text,
      );
      return;
    }

    await prefs.remove(_rememberedEmailPreferenceKey);
    await prefs.remove(_rememberedPasswordPreferenceKey);
  }

  Future<void> _signInWithEmail() {
    return _runAuthAction(() async {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _saveRememberedCredentials();
    });
  }

  Future<void> _signUpWithEmail() {
    return _runAuthAction(() async {
      final email = _signUpEmailController.text.trim();
      final password = _signUpPasswordController.text;
      final confirmPassword = _signUpConfirmPasswordController.text;

      if (email.isEmpty || password.isEmpty) {
        _showMessage('Uzupełnij e-mail i hasło.');
        return;
      }

      if (password != confirmPassword) {
        _showMessage('Hasła muszą być takie same.');
        return;
      }

      await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: kIsWeb ? null : _mobileRedirectUrl,
        data: {'full_name': email.split('@').first},
      );
      _goToAuthStep(2);
    });
  }

  Future<void> _resetPassword() {
    return _runAuthAction(() async {
      final email = _resetEmailController.text.trim();
      if (email.isEmpty) {
        _showMessage('Wpisz e-mail do resetu hasła.');
        return;
      }

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : _mobileRedirectUrl,
      );
      _showMessage('Wysłaliśmy link do zmiany hasła.');
      _goToAuthStep(0);
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToAuthStep(int step) {
    if (_authStep == step) return;
    setState(() {
      _previousAuthStep = _authStep;
      _authStep = step;
    });
  }

  Widget _buildAuthStep() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final isForward = _authStep >= _previousAuthStep;
        final begin = Offset(isForward ? 1 : -1, 0);
        final slideAnimation = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_authStep),
        child: switch (_authStep) {
          1 => _buildSignUpForm(),
          2 => _buildActivationInfo(),
          3 => _buildResetPasswordForm(),
          _ => _buildLoginForm(),
        },
      ),
    );
  }

  int _previousStepForCurrentStep() {
    return switch (_authStep) {
      2 => 1,
      _ => 0,
    };
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        CheckboxListTile(
          value: _rememberMe,
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() => _rememberMe = value ?? false);
                },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Zapamiętaj mnie'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _signInWithEmail,
          child: const Text('Zaloguj'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _isLoading ? null : () => _goToAuthStep(1),
          child: const Text('Utwórz konto'),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => _goToAuthStep(3),
          child: const Text('Nie pamiętasz hasła?'),
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _signUpEmailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _signUpPasswordController,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          decoration: const InputDecoration(labelText: 'Hasło'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _signUpConfirmPasswordController,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          decoration: const InputDecoration(labelText: 'Potwierdź hasło'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _isLoading ? null : _signUpWithEmail,
          child: const Text('Zarejestruj się'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isLoading ? null : () => _goToAuthStep(0),
          child: const Text('Zaloguj się'),
        ),
      ],
    );
  }

  Widget _buildActivationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Aby dokończyć rejestrację konta na Twój adres e-mail został wysłany link aktywacyjny, dokończ rejestrację poprzez wejście na ten link.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: appTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.normal,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _isLoading ? null : () => _goToAuthStep(0),
          child: const Text('Wróć do logowania'),
        ),
      ],
    );
  }

  Widget _buildResetPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _resetEmailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _isLoading ? null : _resetPassword,
          child: const Text('Przypomnij hasło'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/images/d2d-door-ka-logo.png',
                        height: 72,
                      ),
                      const SizedBox(height: 36),
                      _buildAuthStep(),
                      if (_isLoading) ...[
                        const SizedBox(height: 16),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_authStep != 0)
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  tooltip: 'Wróć',
                  onPressed: _isLoading
                      ? null
                      : () => _goToAuthStep(_previousStepForCurrentStep()),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _contactsRefresh = 0;
  int _seenUnprocessedMeetingsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedAvatarPath();
  }

  Future<void> _loadSavedAvatarPath() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_avatarPathPreferenceKey);
    _avatarPathNotifier.value = null;
    _defaultLeadGoalNotifier.value =
        preferences.getInt(_defaultLeadGoalPreferenceKey) ?? 9;
    await _loadCustomContactStatuses();
    await _refreshUnprocessedMeetingsCount();
  }

  void _openAccountPanel() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const Scaffold(
            backgroundColor: appBackground,
            body: AccountPage(),
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
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _openUnprocessedMeetingsPanel() async {
    setState(() {
      _seenUnprocessedMeetingsCount = _unprocessedMeetingsNotifier.value;
    });
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (context) {
        return const Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(top: 70, right: 12, left: 12),
            child: Material(
              color: Colors.transparent,
              child: _UnprocessedMeetingsPopup(),
            ),
          ),
        );
      },
    );
    await _refreshUnprocessedMeetingsCount();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardPage(),
      ContactsPage(refreshSignal: _contactsRefresh),
      const MeetingsPage(),
      ClientsPage(onContactRestored: () => setState(() => _contactsRefresh++)),
      const StatisticsPage(),
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
            padding: const EdgeInsets.only(right: 2),
            child: ValueListenableBuilder<int>(
              valueListenable: _unprocessedMeetingsNotifier,
              builder: (context, count, _) {
                return _TopNotificationsButton(
                  hasPending: count > _seenUnprocessedMeetingsCount,
                  onPressed: _openUnprocessedMeetingsPanel,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              tooltip: 'Konto',
              onPressed: _openAccountPanel,
              icon: const _TopAccountAvatar(),
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

class _TopNotificationsButton extends StatefulWidget {
  const _TopNotificationsButton({
    required this.hasPending,
    required this.onPressed,
  });

  final bool hasPending;
  final VoidCallback onPressed;

  @override
  State<_TopNotificationsButton> createState() =>
      _TopNotificationsButtonState();
}

class _TopNotificationsButtonState extends State<_TopNotificationsButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -0.10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.10, end: 0.10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.10, end: -0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.hasPending) _controller.repeat(reverse: false);
  }

  @override
  void didUpdateWidget(covariant _TopNotificationsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasPending && !_controller.isAnimating) {
      _controller.repeat(reverse: false);
    } else if (!widget.hasPending && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Powiadomienia',
          onPressed: widget.onPressed,
          icon: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) {
              return Transform.rotate(angle: _shake.value, child: child);
            },
            child: const Icon(Icons.notifications_none_outlined),
          ),
        ),
        if (widget.hasPending)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: appDanger,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _TopAccountAvatar extends StatelessWidget {
  const _TopAccountAvatar();

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    return ValueListenableBuilder<String?>(
      valueListenable: _avatarPathNotifier,
      builder: (context, avatarPath, _) {
        return Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F0EA),
            shape: BoxShape.circle,
            border: Border.all(color: appBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: avatarPath == null || avatarPath.isEmpty
              ? Text(
                  _userInitials(user),
                  style: const TextStyle(
                    color: appTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : _AvatarImage(path: avatarPath),
        );
      },
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
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available,
      label: 'Umówione',
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
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }

    return Image.file(
      File(path),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class ContactStatus {
  const ContactStatus(
    this.value,
    this.label,
    this.color, {
    required this.stage,
    this.icon,
    this.isSystem = true,
  });

  final String value;
  final String label;
  final Color color;
  final String stage;
  final IconData? icon;
  final bool isSystem;

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      'color': color.toARGB32(),
      'stage': stage,
      'icon': icon?.codePoint,
    };
  }

  static ContactStatus fromJson(Map<String, dynamic> json) {
    return ContactStatus(
      json['value']?.toString() ?? '',
      json['label']?.toString() ?? '',
      Color((json['color'] as num?)?.toInt() ?? 0xFF6D6A75),
      stage: json['stage']?.toString() ?? 'contact',
      icon: _contactStatusIconFromCodePoint((json['icon'] as num?)?.toInt()),
      isSystem: false,
    );
  }
}

const _contactStatuses = [
  ContactStatus(
    'scheduled_meeting',
    'Umówione spotkanie',
    Color(0xFF2F5D50),
    stage: 'meeting',
  ),
  ContactStatus(
    'meeting_active',
    'Spotkanie trwa',
    Color(0xFF0F766E),
    stage: 'meeting',
  ),
  ContactStatus(
    'meeting_done',
    'Spotkanie odbyte',
    Color(0xFF2374AB),
    stage: 'meeting',
  ),
  ContactStatus(
    'signed_contract',
    'Spisana umowa',
    Color(0xFF1E8E3E),
    stage: 'meeting',
  ),
  ContactStatus(
    'interested',
    'Zainteresowany',
    Color(0xFF5B7CFA),
    stage: 'contact',
  ),
  ContactStatus('contact', 'Kontakt', Color(0xFF6D6A75), stage: 'contact'),
  ContactStatus('postponed', 'Przełożone', Color(0xFFB7791F), stage: 'meeting'),
  ContactStatus(
    'not_interested',
    'Niezainteresowany',
    Color(0xFFD64545),
    stage: 'contact',
  ),
  ContactStatus(
    'no_contact',
    'Brak kontaktu',
    Color(0xFF8A8F98),
    stage: 'contact',
  ),
];

const _defaultContactTypeStatus = ContactStatus(
  'contact_type_default',
  'Typ kontaktu',
  Color(0xFF8A8F98),
  stage: 'contact_type',
);

const _defaultEditableContactStatuses = [
  ContactStatus(
    'to_call',
    'Do przedzwonienia',
    Color(0xFF2374AB),
    stage: 'contact',
    icon: Icons.phone_outlined,
  ),
  ContactStatus(
    'to_visit',
    'Do podjechania',
    Color(0xFFB7791F),
    stage: 'contact',
    icon: Icons.home_outlined,
  ),
  ContactStatus(
    'working',
    'Robocze',
    Color(0xFF6D6A75),
    stage: 'contact',
    icon: Icons.edit_note_outlined,
  ),
];

const _defaultEditableContactTypes = [
  ContactStatus(
    'contact_type_panels_storage',
    'Panele z magazynem energii',
    Color(0xFF2F5D50),
    stage: 'contact_type',
  ),
  ContactStatus(
    'contact_type_subsidy',
    'Dofinansowanie',
    Color(0xFF2374AB),
    stage: 'contact_type',
  ),
  ContactStatus(
    'contact_type_installation_expansion',
    'Rozbudowa instalacji',
    Color(0xFFB7791F),
    stage: 'contact_type',
  ),
];

const _statusPalette = [
  Color(0xFF2F5D50),
  Color(0xFF0F766E),
  Color(0xFF2374AB),
  Color(0xFF5B7CFA),
  Color(0xFF7B61FF),
  Color(0xFFB7791F),
  Color(0xFFF0A202),
  Color(0xFFD64545),
  Color(0xFF6D6A75),
  Color(0xFF2E2D2A),
];

const _contactStatusIconChoices = [
  Icons.phone_outlined,
  Icons.home_outlined,
  Icons.edit_note_outlined,
  Icons.schedule_outlined,
  Icons.priority_high_outlined,
  Icons.person_search_outlined,
  Icons.handshake_outlined,
  Icons.event_available_outlined,
  Icons.warning_amber_rounded,
  Icons.check_circle_outline,
  Icons.close,
  Icons.star_border_rounded,
];

IconData? _contactStatusIconFromCodePoint(int? codePoint) {
  if (codePoint == null) return null;
  for (final icon in _contactStatusIconChoices) {
    if (icon.codePoint == codePoint) return icon;
  }
  return null;
}

Color _automaticStatusColor(String stage) {
  final customCount = _customContactStatusesNotifier.value
      .where((status) => status.stage == stage && !status.isSystem)
      .length;
  return _statusPalette[customCount % _statusPalette.length];
}

const _qualities = ['S', 'M', 'L', 'XL'];

const _meetingStatuses = {
  'scheduled_meeting',
  'meeting_active',
  'meeting_done',
  'signed_contract',
  'postponed',
};

bool _isMeetingStatus(String status) {
  return _meetingStatuses.contains(status) ||
      _customContactStatusesNotifier.value.any(
        (item) => item.value == status && item.stage == 'meeting',
      );
}

bool _isUnprocessedMeeting(Contact contact) {
  if (contact.status != 'scheduled_meeting' || contact.contactDate == null) {
    return false;
  }
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  final contactDay = DateTime(
    contact.contactDate!.year,
    contact.contactDate!.month,
    contact.contactDate!.day,
  );
  return contactDay.isBefore(todayOnly);
}

bool _isCurrentOrUpcomingMeeting(Contact contact) {
  if (!_isMeetingStatus(contact.status) ||
      contact.status == 'signed_contract') {
    return false;
  }
  return !_isUnprocessedMeeting(contact);
}

Future<void> _refreshUnprocessedMeetingsCount() async {
  try {
    final contacts = await _fetchActiveContacts();
    _unprocessedMeetingsNotifier.value = contacts
        .where(_isUnprocessedMeeting)
        .length;
  } catch (_) {
    _unprocessedMeetingsNotifier.value = 0;
  }
}

int _compareContactsByDateAndTime(
  Contact a,
  Contact b, {
  required bool newestFirst,
}) {
  final fallback = newestFirst ? DateTime(1900) : DateTime(9999);
  final aDate = a.contactDate ?? fallback;
  final bDate = b.contactDate ?? fallback;
  final dateCompare = newestFirst
      ? bDate.compareTo(aDate)
      : aDate.compareTo(bDate);
  if (dateCompare != 0) return dateCompare;
  return newestFirst
      ? b.contactTime.compareTo(a.contactTime)
      : a.contactTime.compareTo(b.contactTime);
}

List<Contact> _contactsFromSupabaseData(Object? data) {
  return (data as List)
      .map((item) => Contact.fromMap(Map<String, dynamic>.from(item)))
      .toList();
}

Future<List<Contact>> _fetchActiveContacts() async {
  final data = await _supabase
      .from('contacts')
      .select()
      .isFilter('moved_to_client_at', null);

  return _contactsFromSupabaseData(data);
}

const _notSoldReasons = [
  'Cena',
  'Brak osoby decyzyjnej',
  'Nie teraz',
  'Czeka na decyzję',
  'Inne',
];

ContactStatus _statusByValue(String value) {
  return [
    ..._contactStatuses,
    ..._customContactStatusesNotifier.value,
  ].firstWhere(
    (status) => status.value == value,
    orElse: () => _contactStatuses.first,
  );
}

List<ContactStatus> _statusesForStage(String stage) {
  if (stage == 'contact') {
    return _customContactStatusesNotifier.value
        .where((status) => status.stage == stage)
        .toList();
  }

  return [
    ..._contactStatuses.where((status) => status.stage == stage),
    ..._customContactStatusesNotifier.value.where(
      (status) => status.stage == stage,
    ),
  ];
}

String _stageForContactStatus(String status) {
  return _statusByValue(status).stage;
}

List<String> _contactTypeValuesFromRaw(String raw) {
  return raw
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .take(3)
      .toList();
}

String _contactTypeValuesToRaw(List<String> values) {
  return values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .take(3)
      .join(',');
}

List<ContactStatus> _contactTypeStatusesFor(Contact contact) {
  final rawTypes = contact.contactType.isNotEmpty
      ? contact.contactType
      : contact.contactQuality;
  final values = _contactTypeValuesFromRaw(rawTypes);
  final types = _statusesForStage('contact_type');
  final statuses = <ContactStatus>[];

  for (final value in values) {
    for (final type in types) {
      if (type.value == value) {
        statuses.add(type);
        break;
      }
    }
  }

  if (statuses.isEmpty) return [];
  return statuses.take(3).toList();
}

Future<void> _loadCustomContactStatuses() async {
  final preferences = await SharedPreferences.getInstance();
  final raw = preferences.getString(_customContactStatusesPreferenceKey);
  if (raw == null || raw.isEmpty) {
    final seededStatuses = _seedDefaultEditableStatuses(const []);
    await _saveCustomContactStatuses(seededStatuses);
    return;
  }

  try {
    final decoded = jsonDecode(raw) as List;
    final loadedStatuses = decoded
        .map((item) => ContactStatus.fromJson(Map<String, dynamic>.from(item)))
        .where((status) => status.value.isNotEmpty && status.label.isNotEmpty)
        .toList();
    final seededStatuses = _seedDefaultEditableStatuses(loadedStatuses);
    await _saveCustomContactStatuses(seededStatuses);
  } catch (_) {
    final seededStatuses = _seedDefaultEditableStatuses(const []);
    await _saveCustomContactStatuses(seededStatuses);
  }
}

List<ContactStatus> _seedDefaultEditableStatuses(List<ContactStatus> statuses) {
  final normalizedStatuses = statuses.map(_normalizeEditableStatus).toList();
  final nextStatuses = [...normalizedStatuses];

  void addDefault(ContactStatus defaultStatus) {
    final hasValue = nextStatuses.any(
      (status) => status.value == defaultStatus.value,
    );
    final hasLabel = nextStatuses.any(
      (status) =>
          status.stage == defaultStatus.stage &&
          _normalizedStatusLabel(status.label) ==
              _normalizedStatusLabel(defaultStatus.label),
    );
    if (!hasValue && !hasLabel) nextStatuses.add(defaultStatus);
  }

  for (final status in _defaultEditableContactStatuses) {
    addDefault(status);
  }
  for (final type in _defaultEditableContactTypes) {
    addDefault(type);
  }

  return nextStatuses;
}

ContactStatus _normalizeEditableStatus(ContactStatus status) {
  ContactStatus? matchingDefault;
  for (final defaultStatus in [
    ..._defaultEditableContactStatuses,
    ..._defaultEditableContactTypes,
  ]) {
    if (defaultStatus.value == status.value) {
      matchingDefault = defaultStatus;
      break;
    }
  }

  final normalizedLabel =
      status.stage == 'contact_type' &&
          _normalizedStatusLabel(status.label) == 'dotacja'
      ? 'Dofinansowanie'
      : status.label;

  if (matchingDefault == null &&
      normalizedLabel == status.label &&
      status.icon != null) {
    return status;
  }

  return ContactStatus(
    status.value,
    normalizedLabel,
    status.color,
    stage: status.stage,
    icon: status.icon ?? matchingDefault?.icon,
    isSystem: status.isSystem,
  );
}

String _normalizedStatusLabel(String label) {
  return label.trim().toLowerCase();
}

Future<void> _saveCustomContactStatuses(List<ContactStatus> statuses) async {
  _customContactStatusesNotifier.value = statuses;
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(
    _customContactStatusesPreferenceKey,
    jsonEncode(statuses.map((status) => status.toJson()).toList()),
  );
}

Future<void> _pushSettingsSubpage(BuildContext context, Widget page) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
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

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  late Future<_DashboardData> _dashboardFuture;
  bool _isLeadDayStarted = false;
  bool _isLeadDayPaused = false;
  bool _isWeeklyTileExpanded = true;
  int _sessionCollectedContacts = 0;
  Duration _leadDayElapsed = Duration.zero;
  Duration _leadDayBreakElapsed = Duration.zero;
  DateTime? _leadDayStartedAt;
  DateTime? _leadDayBreakStartedAt;
  Timer? _leadDayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashboardFuture = _fetchDashboardData();
    _restoreLeadDayTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _leadDayTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLeadDayElapsed();
    }
  }

  Future<_DashboardData> _fetchDashboardData() async {
    final contacts = await _fetchActiveContacts();
    final clientsData = await _supabase
        .from('clients')
        .select()
        .isFilter('archived_at', null);
    final leadSessions = await _fetchLeadSessionsForDashboard();

    final clients = clientsData
        .map((item) => Client.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return _DashboardData(
      contacts: contacts,
      clients: clients,
      leadSessions: leadSessions
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

  Future<void> _reload() async {
    try {
      final data = await _fetchDashboardData().timeout(_manualRefreshTimeout);
      if (!mounted) return;
      setState(() => _dashboardFuture = Future.value(data));
    } catch (error) {
      if (!mounted) return;
      _ignoreManualRefreshError(error);
    }
  }

  void _updateDashboardContact(Contact updatedContact) {
    final currentData = _dashboardFuture;
    currentData.then((data) {
      if (!mounted) return;
      final nextContacts = data.contacts
          .map(
            (contact) =>
                contact.id == updatedContact.id ? updatedContact : contact,
          )
          .where((contact) => contact.status != 'signed_contract')
          .toList();
      setState(() {
        _dashboardFuture = Future.value(
          _DashboardData(
            contacts: nextContacts,
            clients: data.clients,
            leadSessions: data.leadSessions,
          ),
        );
      });
    });
  }

  Future<void> _restoreLeadDayTimer() async {
    final preferences = await SharedPreferences.getInstance();
    final startedAtText = preferences.getString(_leadDayStartedAtPreferenceKey);
    final breakStartedAtText = preferences.getString(
      _leadDayBreakStartedAtPreferenceKey,
    );
    final breakSeconds =
        preferences.getInt(_leadDayBreakSecondsPreferenceKey) ?? 0;
    final startedAt = DateTime.tryParse(startedAtText ?? '');
    final breakStartedAt = DateTime.tryParse(breakStartedAtText ?? '');
    if (!mounted || startedAt == null) return;

    final baseBreakElapsed = Duration(seconds: breakSeconds);
    final currentBreakElapsed = breakStartedAt == null
        ? Duration.zero
        : DateTime.now().difference(breakStartedAt);
    final totalBreakElapsed = baseBreakElapsed + currentBreakElapsed;

    setState(() {
      _isLeadDayStarted = true;
      _isLeadDayPaused = breakStartedAt != null;
      _leadDayStartedAt = startedAt;
      _leadDayBreakStartedAt = breakStartedAt;
      _leadDayBreakElapsed = totalBreakElapsed;
      _leadDayElapsed =
          DateTime.now().difference(startedAt) - totalBreakElapsed;
    });
    _startLeadDayTicker();
  }

  void _refreshLeadDayElapsed() {
    final startedAt = _leadDayStartedAt;
    if (!mounted || !_isLeadDayStarted || startedAt == null) {
      return;
    }

    final now = DateTime.now();
    final currentBreakElapsed =
        _isLeadDayPaused && _leadDayBreakStartedAt != null
        ? now.difference(_leadDayBreakStartedAt!)
        : Duration.zero;
    final totalBreakElapsed = _leadDayBreakElapsed + currentBreakElapsed;
    final workElapsed = now.difference(startedAt) - totalBreakElapsed;

    setState(() {
      if (_isLeadDayPaused) {
        _leadDayElapsed = workElapsed.isNegative ? Duration.zero : workElapsed;
      } else {
        _leadDayElapsed = workElapsed.isNegative ? Duration.zero : workElapsed;
      }
    });
  }

  void _startLeadDayTicker() {
    _leadDayTimer?.cancel();
    _leadDayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshLeadDayElapsed();
    });
  }

  Future<void> _startLeadDay() async {
    _leadDayTimer?.cancel();
    final startedAt = DateTime.now();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _leadDayStartedAtPreferenceKey,
      startedAt.toIso8601String(),
    );
    await preferences.remove(_leadDayBreakStartedAtPreferenceKey);
    await preferences.setInt(_leadDayBreakSecondsPreferenceKey, 0);
    if (!mounted) return;

    setState(() {
      _isLeadDayStarted = true;
      _isLeadDayPaused = false;
      _leadDayStartedAt = startedAt;
      _leadDayBreakStartedAt = null;
      _leadDayBreakElapsed = Duration.zero;
      _leadDayElapsed = Duration.zero;
      _sessionCollectedContacts = 0;
    });
    _startLeadDayTicker();
  }

  Future<void> _toggleLeadDayBreak() async {
    if (!_isLeadDayStarted) return;

    final preferences = await SharedPreferences.getInstance();
    final now = DateTime.now();

    if (_isLeadDayPaused) {
      final breakStartedAt = _leadDayBreakStartedAt;
      final breakDuration = breakStartedAt == null
          ? Duration.zero
          : now.difference(breakStartedAt);
      final totalBreakElapsed = _leadDayBreakElapsed + breakDuration;

      await preferences.setInt(
        _leadDayBreakSecondsPreferenceKey,
        totalBreakElapsed.inSeconds,
      );
      await preferences.remove(_leadDayBreakStartedAtPreferenceKey);

      if (!mounted) return;
      setState(() {
        _isLeadDayPaused = false;
        _leadDayBreakStartedAt = null;
        _leadDayBreakElapsed = totalBreakElapsed;
      });
      _refreshLeadDayElapsed();
      return;
    }

    await preferences.setString(
      _leadDayBreakStartedAtPreferenceKey,
      now.toIso8601String(),
    );
    if (!mounted) return;
    setState(() {
      _isLeadDayPaused = true;
      _leadDayBreakStartedAt = now;
    });
    _refreshLeadDayElapsed();
  }

  Future<void> _finishLeadDay() async {
    if (!_isLeadDayStarted) return;

    final preferences = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final breakStartedAt = _leadDayBreakStartedAt;
    final finalBreakElapsed =
        _leadDayBreakElapsed +
        (_isLeadDayPaused && breakStartedAt != null
            ? now.difference(breakStartedAt)
            : Duration.zero);
    final workSeconds = _leadDayElapsed.inSeconds;

    final session = {
      'agent_id': _supabase.auth.currentUser?.id,
      'session_date': _dateOnly(now),
      'scheduled_meetings_count': 0,
      'collected_contacts_count': _sessionCollectedContacts,
      'work_seconds': workSeconds,
      'break_seconds': finalBreakElapsed.inSeconds,
      'created_at': now.toIso8601String(),
    };

    try {
      await _supabase.from('lead_sessions').insert(session);
    } catch (_) {
      _localLeadSessions.add(session);
    }

    await preferences.remove(_leadDayStartedAtPreferenceKey);
    await preferences.remove(_leadDayBreakStartedAtPreferenceKey);
    await preferences.remove(_leadDayBreakSecondsPreferenceKey);

    _leadDayTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isLeadDayStarted = false;
      _isLeadDayPaused = false;
      _leadDayStartedAt = null;
      _leadDayBreakStartedAt = null;
      _leadDayElapsed = Duration.zero;
      _leadDayBreakElapsed = Duration.zero;
      _sessionCollectedContacts = 0;
      _dashboardFuture = _fetchDashboardData();
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
          final scheduledMeetings =
              data.contacts.where((contact) {
                return _isCurrentOrUpcomingMeeting(contact);
              }).toList()..sort(
                (a, b) =>
                    _compareContactsByDateAndTime(a, b, newestFirst: false),
              );
          final collectedContacts = data.contacts
              .where((contact) => !_isMeetingStatus(contact.status))
              .toList();
          final overdueMeetings = data.contacts.where((contact) {
            return _isUnprocessedMeeting(contact);
          }).toList();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _unprocessedMeetingsNotifier.value = overdueMeetings.length;
          });
          final weeklyStats = _buildWeeklyDashboardStats(data);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      onToggleBreak: _toggleLeadDayBreak,
                      onFinish: _finishLeadDay,
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
                    onContactChanged: _updateDashboardContact,
                    onEditMeetingTime: _editDashboardMeetingTime,
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
                const SizedBox(height: 16),
                _DashboardBodyPadding(
                  child: _DashboardList(
                    title: 'Kontakty',
                    emptyText: 'Tutaj pojawią się zebrane leady.',
                    contacts: collectedContacts,
                    leadingIcon: Icons.groups_outlined,
                    onDelete: _deleteDashboardContact,
                    onContactChanged: _updateDashboardContact,
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
    required this.onToggleBreak,
    required this.onFinish,
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
  final VoidCallback onToggleBreak;
  final VoidCallback onFinish;
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                              'Umówione: $currentMeetings/$dailyGoal',
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
                        isPaused: isPaused,
                        onToggleBreak: onToggleBreak,
                        onFinish: onFinish,
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
    required this.isPaused,
    required this.onToggleBreak,
    required this.onFinish,
    required this.onScheduleMeeting,
    required this.onAddLead,
  });

  final bool isPaused;
  final VoidCallback onToggleBreak;
  final VoidCallback onFinish;
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
        const SizedBox(height: 6),
        _ActiveLeadButton(
          label: isPaused ? 'Wznów' : 'Przerwa',
          icon: isPaused
              ? Icons.play_arrow_rounded
              : Icons.pause_circle_outline_rounded,
          onPressed: onToggleBreak,
        ),
        const SizedBox(height: 6),
        _ActiveLeadButton(
          label: 'Koniec',
          icon: Icons.stop_circle_outlined,
          onPressed: onFinish,
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
    this.onContactChanged,
    this.headerTrailing,
    this.onEditMeetingTime,
    this.leadingIcon,
  });

  final String title;
  final String? headerTrailing;
  final String emptyText;
  final List<Contact> contacts;
  final ValueChanged<Contact> onDelete;
  final ValueChanged<Contact>? onContactChanged;
  final ValueChanged<Contact>? onEditMeetingTime;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final useSplitMeetingTiles = onEditMeetingTime != null;

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
                onContactChanged: onContactChanged,
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
                onContactChanged: onContactChanged,
              ),
            ],
        ],
      ),
    );
  }
}

class _RecentContactTile extends StatefulWidget {
  const _RecentContactTile({
    required this.contact,
    required this.onDelete,
    this.onContactChanged,
    this.onEditMeetingTime,
  });

  final Contact contact;
  final VoidCallback onDelete;
  final ValueChanged<Contact>? onContactChanged;
  final VoidCallback? onEditMeetingTime;

  @override
  State<_RecentContactTile> createState() => _RecentContactTileState();
}

class _RecentContactTileState extends State<_RecentContactTile> {
  bool _deleteActionOpen = false;
  double _dragOffset = 0;
  late Contact _displayContact;

  static const double _actionsWidth = 86;

  @override
  void initState() {
    super.initState();
    _displayContact = widget.contact;
  }

  @override
  void didUpdateWidget(covariant _RecentContactTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contact != widget.contact) {
      _displayContact = widget.contact;
    }
  }

  void _closeActions() {
    setState(() {
      _deleteActionOpen = false;
      _dragOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final contact = _displayContact;
    final isMeeting = _isMeetingStatus(contact.status);
    final useMeetingLayout = isMeeting && widget.onEditMeetingTime != null;
    final trailingText = isMeeting
        ? (contact.contactTime.length >= 5
              ? contact.contactTime.substring(0, 5)
              : contact.contactTime)
        : _statusByValue(contact.status).label;
    final tile = useMeetingLayout
        ? _MeetingDashboardTileContent(
            contact: contact,
            timeText: trailingText,
            onEditMeetingTime: widget.onEditMeetingTime,
          )
        : _ContactDashboardTileContent(
            contact: contact,
            trailingText: trailingText,
          );

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          final nextOffset = _dragOffset + details.delta.dx;
          _dragOffset = nextOffset.clamp(-_actionsWidth, 0);
          _deleteActionOpen = _dragOffset < -36;
        });
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (_dragOffset < -36 || velocity < -1100) {
          setState(() {
            _dragOffset = -_actionsWidth;
            _deleteActionOpen = true;
          });
        } else {
          _closeActions();
        }
      },
      onHorizontalDragCancel: () {
        setState(() {
          _dragOffset = _deleteActionOpen ? -_actionsWidth : 0;
        });
      },
      child: Stack(
        children: [
          Positioned.fill(
            right: 0,
            child: Align(
              alignment: Alignment.centerRight,
              child: _SwipeActionButton(
                color: appDanger,
                icon: Icons.delete_outline,
                label: 'Usuń',
                onPressed: () => _confirmDelete(context),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _deleteActionOpen
                  ? _closeActions
                  : () async {
                      final updatedContact = await showContactDetailsSheet(
                        context,
                        contact,
                      );
                      if (updatedContact == null || !mounted) return;
                      setState(() => _displayContact = updatedContact);
                      widget.onContactChanged?.call(updatedContact);
                    },
              child: tile,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 18, 12, 8),
        title: _DialogTitleWithClose(
          title: 'Usunąć kontakt na stałe?',
          onClose: () => Navigator.of(context).pop(false),
        ),
        content: const Text('Kontakt zostanie usunięty z aplikacji.'),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: appDanger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onDelete();
    } else if (mounted) {
      _closeActions();
    }
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

  Future<void> _reload() async {
    try {
      final clients = await _fetchClients().timeout(_manualRefreshTimeout);
      if (!mounted) return;
      setState(() => _clientsFuture = Future.value(clients));
    } catch (error) {
      if (!mounted) return;
      _ignoreManualRefreshError(error);
    }
  }

  void _updateClientInList(Client updatedClient) {
    final hadClient = _clientsCache.any(
      (client) => client.id == updatedClient.id,
    );
    final nextClients = hadClient
        ? [
            for (final client in _clientsCache)
              if (client.id == updatedClient.id) updatedClient else client,
          ]
        : [..._clientsCache, updatedClient];

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
            return LayoutBuilder(
              builder: (context, constraints) {
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: constraints.maxHeight,
                        child: const Center(
                          child: _EmptyState(
                            icon: Icons.precision_manufacturing_outlined,
                            text: 'Nie masz jeszcze realizacji.',
                            detail:
                                'Przesuń kontakt w prawo, gdy umowa jest gotowa do realizacji.',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          final activeClients = clients.where(_isActiveRealization).toList();
          final completedClients = clients
              .where((client) => !_isActiveRealization(client))
              .toList();

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      key: ValueKey(activeClients[index].id),
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
        color: appTextPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appTextPrimary),
        boxShadow: [
          BoxShadow(
            color: appTextPrimary.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
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
  const _ClientTile({
    super.key,
    required this.client,
    required this.onClientChanged,
  });

  final Client client;
  final ValueChanged<Client> onClientChanged;

  @override
  State<_ClientTile> createState() => _ClientTileState();
}

class _ClientTileState extends State<_ClientTile> {
  late Client _displayClient;

  @override
  void initState() {
    super.initState();
    _displayClient = widget.client;
  }

  @override
  void didUpdateWidget(covariant _ClientTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client != widget.client) {
      _displayClient = widget.client;
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = _displayClient;
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
              setState(() => _displayClient = updatedClient);
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
      final updatedData = await _supabase
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
          .eq('id', client.id)
          .select()
          .single();

      if (!mounted) return;
      final updatedClient = Client.fromMap(
        Map<String, dynamic>.from(updatedData),
      );
      setState(() {
        _currentClient = updatedClient;
        _nameController.text = updatedClient.clientName;
        _phoneController.text = updatedClient.phone;
        _correspondenceAddressController.text =
            updatedClient.correspondenceAddress;
        _installationAddressController.text = updatedClient.installationAddress;
        _productController.text = updatedClient.productName;
        _status = updatedClient.status;
        _executionMethod = normalizeExecutionMethod(
          updatedClient.executionMethod,
        );
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

  Future<void> _moveBackToMeeting() async {
    if (_isSaving) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final meetingPayload = {
        'agent_id': user.id,
        'contact_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _installationAddressController.text.trim().isNotEmpty
            ? _installationAddressController.text.trim()
            : _correspondenceAddressController.text.trim(),
        'status': 'scheduled_meeting',
        'note': 'Powrót z realizacji do umówionych spotkań.',
        'contact_date': _dateOnly(DateTime.now().add(const Duration(days: 1))),
        'contact_time': '18:00:00',
        'meeting_time': '18:00:00',
        'moved_to_client_at': null,
        'archived_at': null,
      };

      if (client.sourceContactId.isNotEmpty) {
        await _supabase
            .from('contacts')
            .update(meetingPayload)
            .eq('id', client.sourceContactId);
      } else {
        await _supabase.from('contacts').insert(meetingPayload);
      }

      await _supabase
          .from('clients')
          .update({'archived_at': DateTime.now().toIso8601String()})
          .eq('id', client.id);

      if (!mounted) return;
      Navigator.of(context).pop(client.copyWith(status: 'lost'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Realizacja wróciła do spotkań.')),
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
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _moveBackToMeeting,
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('Wróć do spotkań'),
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
  List<Contact> _contactsCache = [];
  final Set<String> _selectedContactIds = {};
  int _contactTilesResetSignal = 0;

  @override
  void initState() {
    super.initState();
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
    final contacts = await _fetchActiveContacts();
    final visibleContacts = contacts
        .where((contact) => !_isMeetingStatus(contact.status))
        .toList();
    _contactsCache = visibleContacts;
    return visibleContacts;
  }

  Future<void> _reload() async {
    if (!mounted) return;
    try {
      final contacts = await _fetchContacts().timeout(_manualRefreshTimeout);
      if (!mounted) return;
      setState(() => _contactsFuture = Future.value(contacts));
    } catch (error) {
      if (!mounted) return;
      _ignoreManualRefreshError(error);
    }
  }

  Future<void> _addContact() async {
    final saved = await showAddContactSheet(context, initialStatus: 'contact');
    if (saved == true) {
      _reload();
    }
  }

  void _resetOpenContactTiles() {
    if (!mounted) return;
    setState(() => _contactTilesResetSignal++);
  }

  Future<void> _deleteContact(Contact contact) async {
    await _supabase.from('contacts').delete().eq('id', contact.id);
    _reload();
  }

  Future<void> _moveContactToMeeting(Contact contact) async {
    await _supabase
        .from('contacts')
        .update({
          'status': 'scheduled_meeting',
          'contact_date': _dateOnly(
            DateTime.now().add(const Duration(days: 1)),
          ),
          'contact_time': '18:00:00',
          'meeting_time': '18:00:00',
        })
        .eq('id', contact.id);
    _reload();
  }

  void _toggleContactSelection(Contact contact) {
    if (!mounted) return;
    setState(() {
      if (_selectedContactIds.contains(contact.id)) {
        _selectedContactIds.remove(contact.id);
      } else {
        _selectedContactIds.add(contact.id);
      }
    });
  }

  void _updateContactInList(Contact updatedContact) {
    if (_isMeetingStatus(updatedContact.status)) {
      _reload();
      return;
    }

    final hadContact = _contactsCache.any(
      (contact) => contact.id == updatedContact.id,
    );
    final nextContacts = hadContact
        ? [
            for (final contact in _contactsCache)
              if (contact.id == updatedContact.id) updatedContact else contact,
          ]
        : [..._contactsCache, updatedContact];

    setState(() {
      _contactsCache = nextContacts;
      _contactsFuture = Future.value(nextContacts);
    });
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

          if (contacts.isEmpty) {
            return Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: constraints.maxHeight,
                              child: const Center(
                                child: _EmptyState(
                                  icon: Icons.contacts_outlined,
                                  text: 'Nie masz jeszcze kontaktów.',
                                  detail: 'Dodaj pierwszy kontakt.',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: _AddContactHorizontalButton(onPressed: _addContact),
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              Positioned.fill(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _resetOpenContactTiles,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 96),
                      children: [
                        for (final contact in contacts)
                          _ContactTile(
                            key: ValueKey(contact.id),
                            contact: contact,
                            isSelected: _selectedContactIds.contains(
                              contact.id,
                            ),
                            isSelectionMode: _selectedContactIds.isNotEmpty,
                            primaryActionIcon: Icons.event_available_outlined,
                            primaryActionLabel: 'Umów',
                            onPrimaryAction: () =>
                                _moveContactToMeeting(contact),
                            onDelete: () => _deleteContact(contact),
                            onContactChanged: _updateContactInList,
                            onToggleSelection: () =>
                                _toggleContactSelection(contact),
                            resetSignal: _contactTilesResetSignal,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _AddContactHorizontalButton(onPressed: _addContact),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({super.key});

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage> {
  late Future<List<Contact>> _meetingsFuture;
  List<Contact> _meetingsCache = [];
  int _meetingTilesResetSignal = 0;

  @override
  void initState() {
    super.initState();
    _meetingsFuture = _fetchMeetings();
  }

  Future<List<Contact>> _fetchMeetings() async {
    final contacts = await _fetchActiveContacts();
    final meetings = contacts.where(_isCurrentOrUpcomingMeeting).toList();
    _meetingsCache = meetings;
    return meetings;
  }

  Future<void> _reload() async {
    if (!mounted) return;
    try {
      final meetings = await _fetchMeetings().timeout(_manualRefreshTimeout);
      if (!mounted) return;
      setState(() => _meetingsFuture = Future.value(meetings));
    } catch (error) {
      if (!mounted) return;
      _ignoreManualRefreshError(error);
    }
  }

  Future<void> _addMeeting() async {
    final saved = await showAddContactSheet(
      context,
      initialStatus: 'scheduled_meeting',
    );
    if (saved == true) _reload();
  }

  void _resetOpenMeetingTiles() {
    if (!mounted) return;
    setState(() => _meetingTilesResetSignal++);
  }

  void _updateMeetingInList(Contact updatedContact) {
    if (updatedContact.status == 'signed_contract') {
      final nextMeetings = _meetingsCache
          .where((contact) => contact.id != updatedContact.id)
          .toList();
      setState(() {
        _meetingsCache = nextMeetings;
        _meetingsFuture = Future.value(nextMeetings);
      });
      return;
    }

    if (!_isMeetingStatus(updatedContact.status)) {
      _reload();
      return;
    }

    final hadMeeting = _meetingsCache.any(
      (contact) => contact.id == updatedContact.id,
    );
    final nextMeetings = hadMeeting
        ? [
            for (final contact in _meetingsCache)
              if (contact.id == updatedContact.id) updatedContact else contact,
          ]
        : [..._meetingsCache, updatedContact];

    setState(() {
      _meetingsCache = nextMeetings;
      _meetingsFuture = Future.value(nextMeetings);
    });
  }

  Future<void> _moveMeetingToClients(Contact contact) async {
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
        .update({
          'status': 'signed_contract',
          'moved_to_client_at': DateTime.now().toIso8601String(),
        })
        .eq('id', contact.id);

    _updateMeetingInList(contact.copyWith(status: 'signed_contract'));
  }

  Future<void> _deleteMeeting(Contact contact) async {
    await _supabase.from('contacts').delete().eq('id', contact.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      child: FutureBuilder<List<Contact>>(
        future: _meetingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              text: 'Nie udało się pobrać spotkań.',
              detail: snapshot.error.toString(),
            );
          }

          final meetings = snapshot.data ?? [];

          if (meetings.isEmpty) {
            return Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: constraints.maxHeight,
                              child: const Center(
                                child: _EmptyState(
                                  icon: Icons.event_available_outlined,
                                  text: 'Nie masz umówionych spotkań.',
                                  detail:
                                      'Dodaj spotkanie albo przenieś kontakt dalej.',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: _AddContactHorizontalButton(
                      onPressed: _addMeeting,
                      label: 'Dodaj spotkanie',
                      icon: Icons.event_available_outlined,
                    ),
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              Positioned.fill(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _resetOpenMeetingTiles,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 96),
                      children: [
                        for (final meeting in meetings)
                          _ContactTile(
                            key: ValueKey(meeting.id),
                            contact: meeting,
                            isSelected: false,
                            isSelectionMode: false,
                            showContactTypePill: false,
                            showMeetingHeader: true,
                            primaryActionIcon:
                                Icons.precision_manufacturing_outlined,
                            primaryActionLabel: 'Realizacja',
                            onPrimaryAction: () =>
                                _moveMeetingToClients(meeting),
                            onDelete: () => _deleteMeeting(meeting),
                            onContactChanged: _updateMeetingInList,
                            onToggleSelection: () {},
                            resetSignal: _meetingTilesResetSignal,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _AddContactHorizontalButton(
                    onPressed: _addMeeting,
                    label: 'Umów spotkanie',
                    icon: Icons.event_available_outlined,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddContactHorizontalButton extends StatelessWidget {
  const _AddContactHorizontalButton({
    required this.onPressed,
    this.label = 'Dodaj kontakt',
    this.icon = Icons.person_add_alt_1_rounded,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: appBrand,
          foregroundColor: appSurface,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _ContactTile extends StatefulWidget {
  const _ContactTile({
    super.key,
    required this.contact,
    required this.isSelected,
    required this.isSelectionMode,
    required this.primaryActionIcon,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.onDelete,
    required this.onContactChanged,
    required this.onToggleSelection,
    required this.resetSignal,
    this.showContactTypePill = true,
    this.showMeetingHeader = false,
  });

  final Contact contact;
  final bool isSelected;
  final bool isSelectionMode;
  final IconData primaryActionIcon;
  final String primaryActionLabel;
  final Future<void> Function() onPrimaryAction;
  final Future<void> Function() onDelete;
  final ValueChanged<Contact> onContactChanged;
  final VoidCallback onToggleSelection;
  final int resetSignal;
  final bool showContactTypePill;
  final bool showMeetingHeader;

  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  late Contact _displayContact;
  bool _leftActionsOpen = false;
  bool _rightActionsOpen = false;
  double _dragOffset = 0;

  static const double _actionsWidth = 86;
  static const double _clientActionWidth = 86;

  @override
  void initState() {
    super.initState();
    _displayContact = widget.contact;
  }

  @override
  void didUpdateWidget(covariant _ContactTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contact != widget.contact) {
      _displayContact = widget.contact;
    }
    if (oldWidget.resetSignal != widget.resetSignal) {
      setState(() {
        _leftActionsOpen = false;
        _rightActionsOpen = false;
        _dragOffset = 0;
      });
    }
  }

  Future<void> _pickAndSaveContactStatus(
    BuildContext context,
    Contact contact,
  ) async {
    final selected = await _showContactWorkStatusPicker(
      context,
      value: contact.contactStatus,
    );
    if (!mounted || selected == contact.contactStatus) return;

    try {
      final updatedData = await _supabase
          .from('contacts')
          .update({'contact_status': selected})
          .eq('id', contact.id)
          .select()
          .single();
      if (!mounted) return;
      final updatedContact = Contact.fromMap(
        Map<String, dynamic>.from(updatedData),
      );
      setState(() => _displayContact = updatedContact);
      widget.onContactChanged(updatedContact);
    } on PostgrestException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _pickAndSaveContactTypes(
    BuildContext context,
    Contact contact,
  ) async {
    final selected = await _showContactTypesPicker(
      context,
      selectedValues: _contactTypeValuesFromRaw(contact.contactType),
    );
    if (!mounted || selected == null) return;
    final nextRaw = _contactTypeValuesToRaw(selected);
    if (nextRaw == contact.contactType) return;

    try {
      final updatedData = await _supabase
          .from('contacts')
          .update({'contact_type': selected.isEmpty ? null : nextRaw})
          .eq('id', contact.id)
          .select()
          .single();
      if (!mounted) return;
      final updatedContact = Contact.fromMap(
        Map<String, dynamic>.from(updatedData),
      );
      setState(() => _displayContact = updatedContact);
      widget.onContactChanged(updatedContact);
    } on PostgrestException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = _displayContact;
    final status = _statusByValue(contact.status);
    final contactTypeStatuses = _contactTypeStatusesFor(contact);
    final contactWorkStatus =
        contact.contactStatus == null || contact.contactStatus!.isEmpty
        ? null
        : _statusByValue(contact.contactStatus!);
    final subtitle = _contactSubtitle(contact);
    final isMeetingTile =
        widget.showMeetingHeader &&
        _stageForContactStatus(contact.status) == 'meeting';
    final showContactHeader =
        !isMeetingTile &&
        widget.showContactTypePill &&
        (contactTypeStatuses.isNotEmpty || contactWorkStatus != null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            final nextOffset = _dragOffset + details.delta.dx;
            _dragOffset = nextOffset.clamp(-_actionsWidth, _clientActionWidth);
            _leftActionsOpen = _dragOffset > 42;
            _rightActionsOpen = _dragOffset < -36;
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
          } else if (_dragOffset < -36 || velocity < -1100) {
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
                  icon: widget.primaryActionIcon,
                  label: widget.primaryActionLabel,
                  onPressed: () => _confirmPrimaryAction(context),
                ),
              ),
            ),
            Positioned.fill(
              right: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: _SwipeActionButton(
                  color: appDanger,
                  icon: Icons.delete_outline,
                  label: 'Usuń',
                  onPressed: () => _confirmDelete(context),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_dragOffset, 0, 0),
              child: Material(
                color: widget.isSelected ? appBrandSoft : appSurfaceSoft,
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
                      : () async {
                          final updatedContact = await showContactDetailsSheet(
                            context,
                            contact,
                          );
                          if (updatedContact == null) return;
                          setState(() => _displayContact = updatedContact);
                          widget.onContactChanged(updatedContact);
                        },
                  onLongPress: widget.onToggleSelection,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMeetingTile || showContactHeader) ...[
                          Row(
                            children: [
                              Expanded(
                                child: isMeetingTile
                                    ? Text(
                                        _meetingDateTimeText(contact),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: appTextPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      )
                                    : InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () => _pickAndSaveContactTypes(
                                          context,
                                          contact,
                                        ),
                                        child: _ContactTypeDots(
                                          statuses: contactTypeStatuses,
                                        ),
                                      ),
                              ),
                              if (isMeetingTile) ...[
                                const SizedBox(width: 10),
                                Text(
                                  _meetingCity(contact.address),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: appTextSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                              if (!isMeetingTile &&
                                  contactWorkStatus != null) ...[
                                const SizedBox(width: 10),
                                InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => _pickAndSaveContactStatus(
                                    context,
                                    contact,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      contactWorkStatus.icon ??
                                          Icons.label_outline_rounded,
                                      color: contactWorkStatus.color,
                                      size: 21,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: appBorder,
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
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
                            if (!isMeetingTile) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                child: CircleAvatar(
                                  backgroundColor: status.color.withValues(
                                    alpha: 0.14,
                                  ),
                                  foregroundColor: status.color,
                                  child: Text(_initials(contact.contactName)),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                contact.contactName.isEmpty
                                    ? 'Bez nazwy'
                                    : contact.contactName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: appTextPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (!widget.isSelectionMode) ...[
                              const SizedBox(width: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Nawiguj',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: contact.address.isEmpty
                                        ? null
                                        : () => _openMap(
                                            context,
                                            contact.address,
                                          ),
                                    icon: const Icon(Icons.home_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Zadzwoń',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: contact.phone.isEmpty
                                        ? null
                                        : () => _callPhone(
                                            context,
                                            contact.phone,
                                          ),
                                    icon: const Icon(Icons.phone_outlined),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: appBorder,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: appTextSecondary,
                              fontSize: 12,
                            ),
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
      message: 'Kontakt zostanie usunięty z aplikacji.',
      actionLabel: 'Usuń',
      actionColor: appDanger,
    );

    if (confirmed == true) {
      await widget.onDelete();
    }
  }

  Future<void> _confirmPrimaryAction(BuildContext context) async {
    final confirmed = await _confirmContactAction(
      context: context,
      title: 'Umówić spotkanie?',
      message: 'Kontakt zostanie przeniesiony do sekcji Umówione spotkania.',
      actionLabel: widget.primaryActionLabel,
      actionColor: appBrand,
    );

    if (confirmed == true) {
      await widget.onPrimaryAction();
    }
  }

  Future<bool?> _confirmContactAction({
    required BuildContext context,
    required String title,
    required String message,
    required String actionLabel,
    required Color actionColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 18, 12, 8),
        title: _DialogTitleWithClose(
          title: title,
          onClose: () => Navigator.of(context).pop(false),
        ),
        content: Text(message),
        actions: [
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
    if (_stageForContactStatus(contact.status) == 'meeting') {
      return contact.note;
    }

    if (contact.status == 'contact') {
      return contact.note;
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

  String _meetingCity(String address) {
    final trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty) return 'Brak miejscowości';
    final parts = trimmedAddress
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) return parts.last;
    return parts.first;
  }

  String _meetingDateTimeText(Contact contact) {
    if (contact.contactDate == null) {
      return contact.contactTime.isEmpty ? 'Brak terminu' : contact.contactTime;
    }
    if (contact.contactTime.isEmpty) return _shortDate(contact.contactDate!);
    return _displayDateTime(contact.contactDate!, contact.contactTime);
  }
}

class _DialogTitleWithClose extends StatelessWidget {
  const _DialogTitleWithClose({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              tooltip: 'Zamknij',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactStatusPill extends StatelessWidget {
  const _ContactStatusPill({required this.status, this.onTap});

  final ContactStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: status.color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: pill,
    );
  }
}

class _ContactTypeDots extends StatelessWidget {
  const _ContactTypeDots({required this.statuses});

  final List<ContactStatus> statuses;

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Dodaj typ',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: appTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          for (var index = 0; index < statuses.length; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            _ContactTypeChoice(type: statuses[index], selected: true),
          ],
        ],
      ),
    );
  }
}

class _ContactStatusIconWithLabel extends StatelessWidget {
  const _ContactStatusIconWithLabel({required this.status});

  final ContactStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          status.icon ?? Icons.label_outline_rounded,
          color: status.color,
          size: 18,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            status.label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

Future<String?> _showContactWorkStatusPicker(
  BuildContext context, {
  required String? value,
}) {
  final statuses = _statusesForStage('contact');
  final safeValue = statuses.any((status) => status.value == value)
      ? value
      : null;

  return showModalBottomSheet<String?>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      return ValueListenableBuilder<List<ContactStatus>>(
        valueListenable: _customContactStatusesNotifier,
        builder: (context, _, child) {
          final currentStatuses = _statusesForStage('contact');

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Status kontaktu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Zamknij',
                      onPressed: () => Navigator.of(context).pop(value),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: safeValue == null
                            ? appTextSecondary
                            : appBorderStrong,
                      ),
                    ),
                    title: const Text(
                      'Brak statusu',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    trailing: safeValue == null
                        ? const Icon(Icons.check, color: appTextSecondary)
                        : null,
                    onTap: () => Navigator.of(context).pop(null),
                  ),
                ),
                for (final status in currentStatuses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: status.value == safeValue
                              ? status.color
                              : appBorderStrong,
                        ),
                      ),
                      title: _ContactStatusIconWithLabel(status: status),
                      trailing: status.value == safeValue
                          ? Icon(Icons.check, color: status.color)
                          : null,
                      onTap: () => Navigator.of(context).pop(status.value),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<List<String>?> _showContactTypesPicker(
  BuildContext context, {
  required List<String> selectedValues,
}) {
  final types = _statusesForStage('contact_type');
  if (types.isEmpty) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Dodaj najpierw typ kontaktu w ustawieniach.'),
        ),
      );
    return Future.value(null);
  }

  return showModalBottomSheet<List<String>>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      final sheetSelectedValues = [...selectedValues];

      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Typy kontaktu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Zamknij',
                      onPressed: () =>
                          Navigator.of(context).pop(selectedValues),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final type in types)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: sheetSelectedValues.contains(type.value)
                              ? type.color
                              : appBorderStrong,
                        ),
                      ),
                      leading: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: type.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        type.label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      trailing: sheetSelectedValues.contains(type.value)
                          ? Icon(Icons.check, color: type.color)
                          : null,
                      onTap: () {
                        if (sheetSelectedValues.contains(type.value)) {
                          sheetSelectedValues.remove(type.value);
                        } else {
                          if (sheetSelectedValues.length >= 3) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Możesz wybrać maksymalnie 3 typy.',
                                  ),
                                ),
                              );
                            return;
                          }
                          sheetSelectedValues.add(type.value);
                        }
                        Navigator.of(context).pop(sheetSelectedValues);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _ContactTypeSelector extends StatelessWidget {
  const _ContactTypeSelector({
    required this.selectedValues,
    required this.onToggle,
    required this.onOpenSettings,
  });

  final List<String> selectedValues;
  final ValueChanged<ContactStatus> onToggle;
  final VoidCallback onOpenSettings;

  void _showTypePicker(BuildContext context) {
    final sheetSelectedValues = [...selectedValues];
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return ValueListenableBuilder<List<ContactStatus>>(
          valueListenable: _customContactStatusesNotifier,
          builder: (context, _, child) {
            final types = _statusesForStage('contact_type');

            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Typy kontaktu',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Dodaj typ',
                            onPressed: () {
                              Navigator.of(context).pop();
                              onOpenSettings();
                            },
                            icon: const Icon(Icons.add),
                          ),
                          IconButton(
                            tooltip: 'Zamknij',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (types.isEmpty)
                        const Text(
                          'Dodaj typy kontaktów w ustawieniach.',
                          style: TextStyle(color: appTextSecondary),
                        )
                      else
                        for (final type in types)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color:
                                      sheetSelectedValues.contains(type.value)
                                      ? type.color
                                      : appBorderStrong,
                                ),
                              ),
                              leading: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: type.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              title: Text(
                                type.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              trailing: sheetSelectedValues.contains(type.value)
                                  ? Icon(Icons.check, color: type.color)
                                  : null,
                              onTap: () {
                                if (sheetSelectedValues.contains(type.value)) {
                                  setSheetState(
                                    () =>
                                        sheetSelectedValues.remove(type.value),
                                  );
                                } else {
                                  if (sheetSelectedValues.length >= 3) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Możesz wybrać maksymalnie 3 typy.',
                                          ),
                                        ),
                                      );
                                    return;
                                  }
                                  setSheetState(
                                    () => sheetSelectedValues.add(type.value),
                                  );
                                }
                                onToggle(type);
                              },
                            ),
                          ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final types = _statusesForStage('contact_type');
    final selectedTypes = [
      for (final value in selectedValues)
        for (final type in types)
          if (type.value == value) type,
    ];
    final selectedTypeCount = selectedTypes.length;

    if (types.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: appSurfaceSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: appBorder),
              ),
              child: const Text(
                'Dodaj typy kontaktów w ustawieniach.',
                style: TextStyle(color: appTextSecondary, fontSize: 12),
              ),
            ),
          ),
          if (selectedTypeCount < 3) ...[
            const SizedBox(width: 8),
            _ContactTypeAddButton(
              label: selectedTypeCount == 0 ? 'Dodaj typ' : null,
              onTap: () => _showTypePicker(context),
            ),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in selectedTypes)
          _ContactTypeChoice(
            type: type,
            selected: true,
            onTap: () => _showTypePicker(context),
            onLongPress: () => _showTypePicker(context),
          ),
        if (selectedTypeCount < 3)
          _ContactTypeAddButton(
            label: selectedTypeCount == 0 ? 'Dodaj typ' : null,
            onTap: () => _showTypePicker(context),
          ),
      ],
    );
  }
}

class _ContactTypeAddButton extends StatelessWidget {
  const _ContactTypeAddButton({required this.onTap, this.label});

  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final label = this.label;

    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: label == null ? 32 : 90,
          height: label == null ? 32 : null,
          padding: label == null
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: appSurfaceSoft,
            shape: label == null ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: label == null ? null : BorderRadius.circular(999),
            border: Border.all(color: appBorderStrong),
          ),
          child: label == null
              ? const Icon(Icons.add, size: 18, color: appTextSecondary)
              : Text(
                  label,
                  style: const TextStyle(
                    color: appTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ContactTypeChoice extends StatelessWidget {
  const _ContactTypeChoice({
    required this.type,
    required this.selected,
    this.onTap,
    this.onLongPress,
  });

  final ContactStatus type;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? type.color.withValues(alpha: 0.14) : appSurfaceSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? type.color : appBorderStrong,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.label,
              style: TextStyle(
                color: selected ? type.color : appTextSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<ContactStatus?> _showContactTypePicker(
  BuildContext context, {
  required String value,
}) {
  final types = _statusesForStage('contact_type');
  if (types.isEmpty) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Dodaj najpierw typ kontaktu w ustawieniach.'),
        ),
      );
    return Future.value(null);
  }
  final safeValue = types.any((type) => type.value == value)
      ? value
      : types.first.value;

  return showModalBottomSheet<ContactStatus>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Typ kontaktu',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Zamknij',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final type in types)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: type.value == safeValue
                          ? type.color
                          : appBorderStrong,
                    ),
                  ),
                  leading: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: type.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    type.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: type.value == safeValue
                      ? Icon(Icons.check, color: type.color)
                      : null,
                  onTap: () => Navigator.of(context).pop(type),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _StatusPickerField extends StatelessWidget {
  const _StatusPickerField({
    required this.stage,
    required this.value,
    required this.onChanged,
  });

  final String stage;
  final String? value;
  final ValueChanged<String?> onChanged;

  Future<void> _openStatusPicker(
    BuildContext context,
    List<ContactStatus> statuses,
  ) {
    final safeValue = statuses.any((status) => status.value == value)
        ? value
        : null;

    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return ValueListenableBuilder<List<ContactStatus>>(
          valueListenable: _customContactStatusesNotifier,
          builder: (context, _, child) {
            final currentStatuses = _statusesForStage(stage);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Status kontaktu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final created = await showContactStatusEditor(
                            context,
                            stage: stage,
                          );
                          if (created == null) return;
                          onChanged(created.value);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Dodaj status'),
                      ),
                      IconButton(
                        tooltip: 'Zamknij',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: safeValue == null
                              ? appTextSecondary
                              : appBorderStrong,
                        ),
                      ),
                      title: const Text(
                        'Brak statusu',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      trailing: safeValue == null
                          ? const Icon(Icons.check, color: appTextSecondary)
                          : null,
                      onTap: () {
                        onChanged(null);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  for (final status in currentStatuses)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: status.value == safeValue
                                ? status.color
                                : appBorderStrong,
                          ),
                        ),
                        title: _ContactStatusIconWithLabel(status: status),
                        trailing: status.value == safeValue
                            ? Icon(Icons.check, color: status.color)
                            : null,
                        onTap: () {
                          onChanged(status.value);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ContactStatus>>(
      valueListenable: _customContactStatusesNotifier,
      builder: (context, _, child) {
        final statuses = _statusesForStage(stage);
        final selectedStatus = statuses
            .where((status) => status.value == value)
            .firstOrNull;
        if (statuses.isEmpty) {
          return Align(
            alignment: Alignment.centerLeft,
            child: _ContactTypeAddButton(
              label: 'Dodaj status',
              onTap: () async {
                final created = await showContactStatusEditor(
                  context,
                  stage: stage,
                );
                if (created == null) return;
                onChanged(created.value);
              },
            ),
          );
        }

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openStatusPicker(context, statuses),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: appSurfaceSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: appBorderStrong),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedStatus?.label ?? 'Brak statusu',
                    style: TextStyle(
                      color: selectedStatus?.color ?? appTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: appTextSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<ContactStatus?> showContactStatusEditor(
  BuildContext context, {
  required String stage,
  ContactStatus? status,
}) async {
  final nameController = TextEditingController(text: status?.label ?? '');
  final itemName = stage == 'contact_type' ? 'typ' : 'status';
  final rootContext = context;
  var isSaving = false;

  final savedStatus = await showModalBottomSheet<ContactStatus>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (modalContext, setDialogState) {
          final bottom = MediaQuery.viewInsetsOf(sheetContext).bottom;
          Future<void> saveAndClose() async {
            if (isSaving) return;
            FocusScope.of(modalContext).unfocus();
            final label = nameController.text.trim();
            if (label.isEmpty) {
              ScaffoldMessenger.of(rootContext)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('Wpisz nazwę ${itemName}u.')),
                );
              return;
            }

            setDialogState(() => isSaving = true);
            final nextStatus = ContactStatus(
              status?.value ??
                  'custom_${DateTime.now().microsecondsSinceEpoch}',
              label,
              status?.color ?? _automaticStatusColor(stage),
              stage: stage,
              isSystem: false,
            );

            final previousStatuses = [..._customContactStatusesNotifier.value];
            final statuses = [...previousStatuses];
            final index = statuses.indexWhere(
              (item) => item.value == nextStatus.value,
            );
            if (index == -1) {
              statuses.add(nextStatus);
            } else {
              statuses[index] = nextStatus;
            }

            try {
              await _saveCustomContactStatuses(statuses);
              if (!modalContext.mounted) return;
              Navigator.of(modalContext).pop(nextStatus);
              return;
            } catch (error) {
              _customContactStatusesNotifier.value = previousStatuses;
              if (rootContext.mounted) {
                ScaffoldMessenger.of(rootContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text('Nie udało się zapisać: $error')),
                  );
              }
            }
            if (modalContext.mounted) {
              setDialogState(() => isSaving = false);
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        status == null ? 'Dodaj $itemName' : 'Edytuj $itemName',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Zamknij',
                      onPressed: () => Navigator.pop(modalContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(labelText: 'Nazwa ${itemName}u'),
                  onSubmitted: (_) => saveAndClose(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isSaving ? null : saveAndClose,
                  child: Text(isSaving ? 'Zapisuję...' : 'Zapisz'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  nameController.dispose();
  if (savedStatus != null && rootContext.mounted) {
    ScaffoldMessenger.of(rootContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Zapisano $itemName.')));
  }

  return savedStatus;
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

Future<Contact?> showContactDetailsSheet(
  BuildContext context,
  Contact contact,
) {
  return showModalBottomSheet<Contact>(
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
  String? _contactWorkStatus;
  late List<String> _contactTypes;
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
    final initialStatus = contact.status == 'signed_contract'
        ? 'scheduled_meeting'
        : contact.status;
    final initialStage = _stageForContactStatus(initialStatus);
    final stageStatuses = _statusesForStage(initialStage);
    _status = initialStage == 'contact'
        ? 'contact'
        : stageStatuses.any((status) => status.value == initialStatus)
        ? initialStatus
        : stageStatuses.first.value;
    final contactStatuses = _statusesForStage('contact');
    _contactWorkStatus =
        contact.contactStatus != null &&
            contactStatuses.any(
              (status) => status.value == contact.contactStatus,
            )
        ? contact.contactStatus
        : null;
    _contactDate =
        contact.contactDate ?? DateTime.now().add(const Duration(days: 1));
    _contactTime = _timeOfDayFromText(contact.contactTime);
    _contactQuality = contact.contactQuality.isEmpty
        ? null
        : contact.contactQuality;
    _contactTypes = _contactTypeValuesFromRaw(
      contact.contactType.isNotEmpty
          ? contact.contactType
          : contact.contactQuality,
    );
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
        'status': _stageForContactStatus(_status) == 'contact'
            ? 'contact'
            : _status,
        'contact_status': _stageForContactStatus(_status) == 'contact'
            ? _contactWorkStatus
            : null,
        'note': _noteController.text.trim(),
        'contact_date': null,
        'contact_time': null,
        'meeting_time': null,
        'contact_notification': null,
        'contact_type': _contactTypes.isEmpty
            ? null
            : _contactTypeValuesToRaw(_contactTypes),
      };

      if (_stageForContactStatus(_status) == 'meeting') {
        payload.addAll({
          'contact_date': _dateOnly(_contactDate),
          'contact_time': _timeOnly(_contactTime),
          'meeting_time': _timeOnly(_contactTime),
          'contact_quality': _contactQuality,
        });
      }

      final updatedData = await _supabase
          .from('contacts')
          .update(payload)
          .eq('id', contact.id)
          .select()
          .single();

      if (!mounted) return;
      final updatedContact = Contact.fromMap(
        Map<String, dynamic>.from(updatedData),
      );
      Navigator.of(context).pop(updatedContact);
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
      final updatedData = await _supabase
          .from('contacts')
          .update(payload)
          .eq('id', contact.id)
          .select()
          .single();
      if (!mounted) return;
      final updatedContact = Contact.fromMap(
        Map<String, dynamic>.from(updatedData),
      );
      Navigator.of(context).pop(updatedContact);
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

  Future<void> _deleteCurrentContact() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _supabase.from('contacts').delete().eq('id', contact.id);
      if (!mounted) return;
      Navigator.of(context).pop(contact.copyWith(status: 'not_interested'));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kontakt został usunięty.')));
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  Future<void> _finishNotSold() async {
    final reason = await _askReason(
      title: 'Dlaczego niesprzedane?',
      reasons: _notSoldReasons,
    );
    if (reason == null || !mounted) return;

    final insight = await _askText(
      title: 'Wnioski na przyszłość',
      label: 'Co następnym razem zrobić lepiej?',
      primaryLabel: 'Dalej',
      secondaryLabel: 'Pomiń',
      allowEmpty: true,
    );
    if (insight == null || !mounted) return;

    final isWaitingForDecision = reason == 'Czeka na decyzję';
    final reminderDate = isWaitingForDecision
        ? await _askReminderDate(title: 'Kiedy wrócić do decyzji?')
        : null;
    if (isWaitingForDecision && (reminderDate == null || !mounted)) return;

    if (isWaitingForDecision) {
      await _updateContact({
        'status': 'scheduled_meeting',
        'meeting_result': 'interested',
        'not_interested_reason': _meetingReasonSummary(reason, insight),
        'contact_notification': reminderDate?.toIso8601String(),
        'note': _mergeNote('Wynik spotkania: nie sprzedane.'),
      });
      return;
    }

    final nextAction = await _askNotSoldNextAction();
    if (nextAction == null || !mounted) return;

    await _updateContact({
      'status': nextAction == 'return_to_contacts' ? 'contact' : 'meeting_done',
      'meeting_result': 'missed',
      'not_interested_reason': _meetingReasonSummary(reason, insight),
      'contact_notification': null,
      'contact_status': nextAction == 'return_to_contacts'
          ? _contactWorkStatus
          : null,
      'note': _mergeNote('Wynik spotkania: nie sprzedane.'),
    });
  }

  Future<void> _finishMissedMeeting() async {
    final shouldPostpone = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Przekładamy?'),
        content: const Text('Spotkanie się nie odbyło. Co robimy dalej?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nie'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tak'),
          ),
        ],
      ),
    );

    if (shouldPostpone == null || !mounted) return;
    if (shouldPostpone) {
      await _postponeMeeting();
      return;
    }

    final nextAction = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Co robimy?'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Usuń'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'remember_meeting'),
            child: const Text('Zapamiętaj spotkanie'),
          ),
        ],
      ),
    );

    if (nextAction == null || !mounted) return;
    if (nextAction == 'delete') {
      await _deleteCurrentContact();
      return;
    }

    await _updateContact({
      'status': 'meeting_done',
      'meeting_result': 'missed',
      'not_interested_reason': 'Nieodbyte',
      'contact_notification': null,
      'note': _mergeNote('Wynik spotkania: nieodbyte.'),
    });
  }

  Future<void> _finishSignedContract() async {
    await _moveContactToClients();
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

      final updatedData = await _supabase
          .from('contacts')
          .update({
            'status': 'signed_contract',
            'moved_to_client_at': DateTime.now().toIso8601String(),
            'note': _mergeNote(
              'Wynik spotkania: spisana umowa. Przeniesiono do W realizacji.',
            ),
          })
          .eq('id', contact.id)
          .select()
          .single();

      if (!mounted) return;
      final updatedContact = Contact.fromMap(
        Map<String, dynamic>.from(updatedData),
      );
      Navigator.of(context).pop(updatedContact);
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

  Future<String?> _askReason({
    required String title,
    required List<String> reasons,
  }) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          for (final reason in reasons)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, reason),
              child: Text(reason),
            ),
        ],
      ),
    );

    if (reason != 'Inne' || !mounted) return reason;

    final controller = TextEditingController();
    final customReason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wpisz powód'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Powód'),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              Navigator.pop(context, value.isEmpty ? null : value);
            },
            child: const Text('Dalej'),
          ),
        ],
      ),
    );
    controller.dispose();
    return customReason;
  }

  Future<String?> _askText({
    required String title,
    required String label,
    required String primaryLabel,
    String? secondaryLabel,
    bool allowEmpty = false,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          if (secondaryLabel != null)
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: Text(secondaryLabel),
            ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (!allowEmpty && text.isEmpty) return;
              Navigator.pop(context, text);
            },
            child: Text(primaryLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  String _meetingReasonSummary(String reason, String insight) {
    final trimmedInsight = insight.trim();
    if (trimmedInsight.isEmpty) return reason;
    return '$reason | Wnioski: $trimmedInsight';
  }

  Future<String?> _askNotSoldNextAction() {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Co dalej z kontaktem?'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'remember_meeting'),
            child: const Text('Zapamiętaj spotkanie'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'return_to_contacts'),
            child: const Text('Wróć do kontaktów'),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _askReminderDate({required String title}) {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: title,
    );
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

  Future<void> _toggleContactType(ContactStatus type) async {
    final nextTypes = [..._contactTypes];
    if (nextTypes.contains(type.value)) {
      nextTypes.remove(type.value);
    } else {
      if (nextTypes.length >= 3) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Możesz wybrać maksymalnie 3 typy.')),
          );
        return;
      }
      nextTypes.add(type.value);
    }

    setState(() => _contactTypes = nextTypes);

    try {
      await _supabase
          .from('contacts')
          .update({
            'contact_type': nextTypes.isEmpty
                ? null
                : _contactTypeValuesToRaw(nextTypes),
          })
          .eq('id', contact.id)
          .select()
          .single();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Typ kontaktu zapisany.')));
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusByValue(_status);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isMeeting = _stageForContactStatus(_status) == 'meeting';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                      if (isMeeting &&
                          contact.contactDate != null &&
                          contact.contactTime.isNotEmpty)
                        const SizedBox(height: 4),
                      if (isMeeting &&
                          contact.contactDate != null &&
                          contact.contactTime.isNotEmpty)
                        Text(
                          _displayDateTime(
                            contact.contactDate!,
                            contact.contactTime,
                          ),
                          style: const TextStyle(
                            color: appTextSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Zamknij',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
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
            if (!isMeeting) ...[
              const SizedBox(height: 10),
              _ContactTypeSelector(
                selectedValues: _contactTypes,
                onToggle: _toggleContactType,
                onOpenSettings: () =>
                    _pushSettingsSubpage(context, const ContactStatusesPage()),
              ),
            ],
            if (_status == 'scheduled_meeting' ||
                _status == 'meeting_active' ||
                _status == 'postponed') ...[
              const SizedBox(height: 12),
              _MeetingActionPanel(
                onSold: _finishSignedContract,
                onNotSold: _finishNotSold,
                onPostpone: _postponeMeeting,
                onMissed: _finishMissedMeeting,
              ),
            ],
            const SizedBox(height: 18),
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
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Adres'),
              onChanged: (_) => setState(() {}),
            ),

            if (!isMeeting) ...[
              const SizedBox(height: 12),
              _StatusPickerField(
                stage: 'contact',
                value: _contactWorkStatus,
                onChanged: (value) =>
                    setState(() => _contactWorkStatus = value),
              ),
            ],
            if (isMeeting) ...[
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
    required this.onSold,
    required this.onNotSold,
    required this.onPostpone,
    required this.onMissed,
  });

  final VoidCallback onSold;
  final VoidCallback onNotSold;
  final VoidCallback onPostpone;
  final VoidCallback onMissed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MeetingQuickActionTile(
            label: 'Sprzedane',
            icon: Icons.check,
            color: appSuccess,
            onTap: onSold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MeetingQuickActionTile(
            label: 'Nie sprzedane',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFF0A202),
            onTap: onNotSold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MeetingQuickActionTile(
            label: 'Przełożone',
            icon: Icons.arrow_forward_rounded,
            color: appInfo,
            onTap: onPostpone,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MeetingQuickActionTile(
            label: 'Nieodbyte',
            icon: Icons.close,
            color: appDanger,
            onTap: onMissed,
          ),
        ),
      ],
    );
  }
}

class _MeetingQuickActionTile extends StatelessWidget {
  const _MeetingQuickActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
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
    required this.displayTitle,
    required this.value,
  });

  final String id;
  final String displayTitle;
  final String value;
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

  Future<void> _reload() async {
    try {
      final data = await _fetchStatsData().timeout(_manualRefreshTimeout);
      if (!mounted) return;
      setState(() => _statsFuture = Future.value(data));
    } catch (error) {
      if (!mounted) return;
      _ignoreManualRefreshError(error);
    }
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
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      displayTitle: 'Dodane kontakty',
                      value: contacts.length.toString(),
                    ),
                    _StatsTileData(
                      id: 'clients',
                      displayTitle: 'W realizacji',
                      value: clients.length.toString(),
                    ),
                    _StatsTileData(
                      id: 'signed_clients',
                      displayTitle: 'Spisani klienci',
                      value: signedClients.toString(),
                    ),
                    _StatsTileData(
                      id: 'lead_time',
                      displayTitle: 'Czas leadowania',
                      value: _formatDuration(
                        Duration(seconds: totalLeadSeconds),
                      ),
                    ),
                    _StatsTileData(
                      id: 'lead_sessions',
                      displayTitle: 'Sesje leadowania',
                      value: leadSessions.length.toString(),
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
                Text(
                  tile.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: appTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tile.value,
                  style: const TextStyle(
                    color: appTextPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = constraints.maxWidth < 380
            ? 0.78
            : constraints.maxWidth < 520
            ? 0.9
            : 1.05;

        return GridView.count(
          crossAxisCount: 2,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final tile in tiles) _StatsTile(tile: tile, onTap: () {}),
          ],
        );
      },
    );
  }
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _leadCycleCount = 2;
  bool _showWeeklyGoal = true;
  bool _productPanels = true;
  bool _productStorage = true;
  bool _productRoofs = false;
  bool _productSets = false;
  bool _productInsulation = false;
  bool _productHeating = false;
  bool _productWindTurbines = false;
  int _defaultLeadGoal = 9;

  void _pushAccountPage(Widget page) {
    _pushSettingsSubpage(context, page);
  }

  void _openSettingsCategory({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    _pushAccountPage(
      _SettingsDetailPage(title: title, icon: icon, children: children),
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

  Future<void> _signOut() async {
    final signOutFuture = _supabase.auth.signOut(scope: SignOutScope.local);
    _authRefreshNotifier.value++;

    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);

    unawaited(
      signOutFuture
          .then<void>((_) {
            _authRefreshNotifier.value++;
          })
          .catchError((Object error) {
            if (!mounted) return;
            final message = error is AuthException
                ? error.message
                : 'Nie udało się wylogować. Spróbuj ponownie.';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final email = user?.email ?? '';
    final name = _userDisplayName(user);

    return Stack(
      children: [
        Positioned.fill(
          top: 72,
          child: _PageShell(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                              subtitle: 'Dane agenta i wylogowanie',
                              onTap: () => _openSettingsCategory(
                                title: 'Konto',
                                icon: Icons.person_outline,
                                children: [
                                  _SettingsRow(
                                    icon: Icons.badge_outlined,
                                    label: 'Imię i nazwisko',
                                    value: name,
                                  ),
                                  _SettingsRow(
                                    icon: Icons.alternate_email_outlined,
                                    label: 'Adres e-mail',
                                    value: email.isEmpty
                                        ? 'Brak e-maila'
                                        : email,
                                  ),
                                  const _SettingsRow(
                                    icon: Icons.phone_outlined,
                                    label: 'Numer telefonu',
                                    value: 'Opcjonalny',
                                  ),
                                  const _SettingsRow(
                                    icon: Icons.confirmation_number_outlined,
                                    label: 'Numer agenta',
                                    value: 'Do uzupełnienia',
                                  ),
                                  _SettingsAction(
                                    icon: Icons.logout_outlined,
                                    label: 'Wyloguj',
                                    onTap: _signOut,
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
                              icon: Icons.directions_walk,
                              title: 'System pracy - leadowanie',
                              subtitle: 'Cykle i cele spotkań',
                              onTap: () => _openSettingsCategory(
                                title: 'System pracy - leadowanie',
                                icon: Icons.directions_walk,
                                children: [
                                  _SettingsRow(
                                    icon: Icons.repeat_outlined,
                                    label: 'Ilość cykli',
                                    value: '$_leadCycleCount',
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => setState(
                                            () => _leadCycleCount = 2,
                                          ),
                                          child: const Text('2 cykle'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => setState(
                                            () => _leadCycleCount = 3,
                                          ),
                                          child: const Text('3 cykle'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _SettingsAction(
                                    icon: Icons.flag_outlined,
                                    label:
                                        'Il. um. spotkań - cel: $_defaultLeadGoal',
                                    onTap: _editDefaultLeadGoal,
                                  ),
                                  _SettingsSwitch(
                                    icon: Icons.calendar_view_week_outlined,
                                    label: 'Pokazywać cel tygodniowy?',
                                    value: _showWeeklyGoal,
                                    onChanged: (value) =>
                                        setState(() => _showWeeklyGoal = value),
                                  ),
                                ],
                              ),
                            ),
                            _SettingsCategoryTile(
                              icon: Icons.handshake_outlined,
                              title: 'Sprzedaż',
                              subtitle: 'Produkty',
                              onTap: () => _openSettingsCategory(
                                title: 'Sprzedaż',
                                icon: Icons.handshake_outlined,
                                children: [
                                  _SettingsSwitch(
                                    icon: Icons.solar_power_outlined,
                                    label: 'Panele',
                                    value: _productPanels,
                                    onChanged: (value) =>
                                        setState(() => _productPanels = value),
                                  ),
                                  _SettingsSwitch(
                                    icon: Icons.battery_charging_full_outlined,
                                    label: 'Magazyny',
                                    value: _productStorage,
                                    onChanged: (value) =>
                                        setState(() => _productStorage = value),
                                  ),
                                  _SettingsSwitch(
                                    icon: Icons.roofing_outlined,
                                    label: 'Dachy',
                                    value: _productRoofs,
                                    onChanged: (value) =>
                                        setState(() => _productRoofs = value),
                                  ),
                                  _SettingsSwitch(
                                    icon: Icons.widgets_outlined,
                                    label: 'Zestawy',
                                    value: _productSets,
                                    onChanged: (value) =>
                                        setState(() => _productSets = value),
                                  ),
                                  _SettingsSwitch(
                                    icon: Icons.texture_outlined,
                                    label: 'Ocieplenia',
                                    value: _productInsulation,
                                    onChanged: (value) => setState(
                                      () => _productInsulation = value,
                                    ),
                                  ),
                                  _SettingsSwitch(
                                    icon: Icons.thermostat_outlined,
                                    label: 'Ogrzewanie',
                                    value: _productHeating,
                                    onChanged: (value) =>
                                        setState(() => _productHeating = value),
                                  ),
                                  _SettingsSwitch(
                                    icon: Icons.air_outlined,
                                    label: 'Turbiny wiatrowe',
                                    value: _productWindTurbines,
                                    onChanged: (value) => setState(
                                      () => _productWindTurbines = value,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _SettingsCategoryTile(
                              icon: Icons.sell_outlined,
                              title: 'Kontakty',
                              subtitle: 'Typy kontaktów i statusy',
                              onTap: () =>
                                  _pushAccountPage(const ContactStatusesPage()),
                            ),
                            _SettingsCategoryTile(
                              icon: Icons.pending_actions_outlined,
                              title: 'Historia / nierozliczone spotkania',
                              subtitle: 'Spotkania wymagające decyzji',
                              onTap: () => _openSettingsCategory(
                                title: 'Historia',
                                icon: Icons.pending_actions_outlined,
                                children: const [_UnprocessedMeetingsList()],
                              ),
                            ),
                            const _SettingsCategoryTile(
                              icon: Icons.info_outline,
                              title: 'Wersja aplikacji: 0.0.1',
                              subtitle: '0.0.1',
                              onTap: null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _SettingsPanelCloseButton(
            onClose: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}

class _SettingsPanelCloseButton extends StatelessWidget {
  const _SettingsPanelCloseButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
        child: Align(
          alignment: Alignment.topRight,
          child: IconButton(
            tooltip: 'Zamknij',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ),
      ),
    );
  }
}

class ContactStatusesPage extends StatelessWidget {
  const ContactStatusesPage({super.key});

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
        title: const Text(
          'Kontakty',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: appBorder),
        ),
      ),
      body: _PageShell(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: ValueListenableBuilder<List<ContactStatus>>(
            valueListenable: _customContactStatusesNotifier,
            builder: (context, _, child) {
              return ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: const [
                  _StatusStageSection(
                    stage: 'contact_type',
                    title: 'Typy kontaktów',
                  ),
                  SizedBox(height: 16),
                  _StatusStageSection(
                    stage: 'contact',
                    title: 'Statusy kontaktów',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusStageSection extends StatefulWidget {
  const _StatusStageSection({required this.stage, required this.title});

  final String stage;
  final String title;

  @override
  State<_StatusStageSection> createState() => _StatusStageSectionState();
}

class _StatusStageSectionState extends State<_StatusStageSection> {
  final _inlineController = TextEditingController();
  final _inlineFocusNode = FocusNode();
  ContactStatus? _editingStatus;
  bool _isEditingInline = false;
  bool _isSavingInline = false;

  @override
  void initState() {
    super.initState();
    _inlineFocusNode.addListener(_handleInlineFocusChange);
  }

  @override
  void dispose() {
    _inlineFocusNode.removeListener(_handleInlineFocusChange);
    _inlineFocusNode.dispose();
    _inlineController.dispose();
    super.dispose();
  }

  void _handleInlineFocusChange() {
    if (!_inlineFocusNode.hasFocus && _isEditingInline) {
      _saveInlineStatus();
    }
  }

  Future<void> _deleteStatus(ContactStatus status) async {
    final statuses = [..._customContactStatusesNotifier.value]
      ..removeWhere((item) => item.value == status.value);
    await _saveCustomContactStatuses(statuses);
    if (mounted) setState(() {});
  }

  Future<void> _changeStatusColor(ContactStatus status) async {
    final pickedColor = await showModalBottomSheet<Color>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Wybierz kolor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in _statusPalette)
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Navigator.of(context).pop(color),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color == status.color
                                ? appTextPrimary
                                : appBorder,
                            width: color == status.color ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (pickedColor == null || pickedColor == status.color) return;

    final previousStatuses = [..._customContactStatusesNotifier.value];
    final statuses = [
      for (final item in previousStatuses)
        if (item.value == status.value)
          ContactStatus(
            item.value,
            item.label,
            pickedColor,
            stage: item.stage,
            icon: item.icon,
            isSystem: item.isSystem,
          )
        else
          item,
    ];

    try {
      await _saveCustomContactStatuses(statuses);
      if (mounted) setState(() {});
    } catch (error) {
      _customContactStatusesNotifier.value = previousStatuses;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Nie udało się zmienić koloru: $error')),
        );
    }
  }

  void _startInlineEdit([ContactStatus? status]) {
    setState(() {
      _editingStatus = status;
      _isEditingInline = true;
      _inlineController.text = status?.label ?? '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _inlineFocusNode.requestFocus();
      _inlineController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _inlineController.text.length,
      );
    });
  }

  Future<void> _changeStatusIcon(ContactStatus status) async {
    final pickedIcon = await showModalBottomSheet<IconData>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Wybierz ikonę',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final icon in _contactStatusIconChoices)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pop(icon),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: status.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: icon == status.icon
                                ? status.color
                                : appBorder,
                            width: icon == status.icon ? 2 : 1,
                          ),
                        ),
                        child: Icon(icon, color: status.color, size: 22),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (pickedIcon == null || pickedIcon == status.icon) return;

    final previousStatuses = [..._customContactStatusesNotifier.value];
    final statuses = [
      for (final item in previousStatuses)
        if (item.value == status.value)
          ContactStatus(
            item.value,
            item.label,
            item.color,
            stage: item.stage,
            icon: pickedIcon,
            isSystem: item.isSystem,
          )
        else
          item,
    ];

    try {
      await _saveCustomContactStatuses(statuses);
      if (mounted) setState(() {});
    } catch (error) {
      _customContactStatusesNotifier.value = previousStatuses;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Nie udało się zmienić ikony: $error')),
        );
    }
  }

  Future<void> _saveInlineStatus() async {
    if (_isSavingInline) return;
    final label = _inlineController.text.trim();
    final editingStatus = _editingStatus;

    if (label.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isEditingInline = false;
        _editingStatus = null;
        _inlineController.clear();
      });
      return;
    }

    setState(() => _isSavingInline = true);

    final nextStatus = ContactStatus(
      editingStatus?.value ?? 'custom_${DateTime.now().microsecondsSinceEpoch}',
      label,
      editingStatus?.color ?? _automaticStatusColor(widget.stage),
      stage: widget.stage,
      icon:
          editingStatus?.icon ??
          (widget.stage == 'contact' ? Icons.label_outline_rounded : null),
      isSystem: false,
    );

    final previousStatuses = [..._customContactStatusesNotifier.value];
    final statuses = [...previousStatuses];
    final index = statuses.indexWhere((item) => item.value == nextStatus.value);
    if (index == -1) {
      statuses.add(nextStatus);
    } else {
      statuses[index] = nextStatus;
    }

    try {
      await _saveCustomContactStatuses(statuses);
      if (!mounted) return;
      setState(() {
        _isEditingInline = false;
        _isSavingInline = false;
        _editingStatus = null;
        _inlineController.clear();
      });
    } catch (error) {
      _customContactStatusesNotifier.value = previousStatuses;
      if (!mounted) return;
      setState(() => _isSavingInline = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Nie udało się zapisać: $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = _statusesForStage(widget.stage);
    final customStatuses = statuses
        .where((status) => !status.isSystem)
        .toList();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_inlineFocusNode.hasFocus) {
          _inlineFocusNode.unfocus();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: appTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final status in customStatuses)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _isEditingInline && _editingStatus?.value == status.value
                  ? _InlineStatusEditorTile(
                      controller: _inlineController,
                      focusNode: _inlineFocusNode,
                      isSaving: _isSavingInline,
                      stage: widget.stage,
                      onSubmitted: _saveInlineStatus,
                    )
                  : Dismissible(
                      key: ValueKey('status-${status.value}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 18),
                        decoration: BoxDecoration(
                          color: appDanger,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) => _deleteStatus(status),
                      child: Material(
                        color: appSurface,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _startInlineEdit(status),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: appBorder),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: widget.stage == 'contact_type'
                                      ? () => _changeStatusColor(status)
                                      : () => _changeStatusIcon(status),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 2,
                                    ),
                                    child: widget.stage == 'contact_type'
                                        ? Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: status.color,
                                              shape: BoxShape.circle,
                                            ),
                                          )
                                        : Icon(
                                            status.icon ??
                                                Icons.label_outline_rounded,
                                            color: status.color,
                                            size: 18,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 1,
                                  height: 26,
                                  color: appBorder,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    status.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _isEditingInline && _editingStatus == null
                ? _InlineStatusEditorTile(
                    controller: _inlineController,
                    focusNode: _inlineFocusNode,
                    isSaving: _isSavingInline,
                    stage: widget.stage,
                    onSubmitted: _saveInlineStatus,
                  )
                : _InlineStatusAddTile(
                    label: widget.stage == 'contact_type'
                        ? 'Dodaj typ'
                        : 'Dodaj status',
                    onTap: () => _startInlineEdit(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InlineStatusAddTile extends StatelessWidget {
  const _InlineStatusAddTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: appSurfaceSoft,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: appBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.add, size: 18, color: appTextSecondary),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: appTextSecondary,
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

class _InlineStatusEditorTile extends StatelessWidget {
  const _InlineStatusEditorTile({
    required this.controller,
    required this.focusNode,
    required this.isSaving,
    required this.stage,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSaving;
  final String stage;
  final Future<void> Function() onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isSaving,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintText: 'Wpisz nazwę',
              ),
              onTapOutside: (_) => focusNode.unfocus(),
              onSubmitted: (_) => onSubmitted(),
            ),
          ),
          if (isSaving)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
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
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? 'Brak adresu e-mail' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
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
  final VoidCallback? onTap;

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
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: appTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.chevron_right, color: appTextSecondary),
                ],
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
    final contacts = await _fetchActiveContacts();
    return contacts.where(_isUnprocessedMeeting).toList()
      ..sort((a, b) => _compareContactsByDateAndTime(a, b, newestFirst: true));
  }

  Future<void> _reload() async {
    try {
      final meetings = await _fetchMeetings().timeout(_manualRefreshTimeout);
      if (!mounted) return;
      setState(() => _meetingsFuture = Future.value(meetings));
    } catch (error) {
      if (!mounted) return;
      _ignoreManualRefreshError(error);
    }
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

class _UnprocessedMeetingsPopup extends StatefulWidget {
  const _UnprocessedMeetingsPopup();

  @override
  State<_UnprocessedMeetingsPopup> createState() =>
      _UnprocessedMeetingsPopupState();
}

class _UnprocessedMeetingsPopupState extends State<_UnprocessedMeetingsPopup> {
  late Future<List<Contact>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _meetingsFuture = _fetchMeetings();
  }

  Future<List<Contact>> _fetchMeetings() async {
    final contacts = await _fetchActiveContacts();
    return contacts.where(_isUnprocessedMeeting).toList()
      ..sort((a, b) => _compareContactsByDateAndTime(a, b, newestFirst: true));
  }

  Future<void> _reload() async {
    final meetings = await _fetchMeetings();
    if (!mounted) return;
    setState(() => _meetingsFuture = Future.value(meetings));
    _unprocessedMeetingsNotifier.value = meetings.length;
  }

  Future<void> _postponeAllNextWeek(List<Contact> meetings) async {
    final nextWeek = DateTime.now().add(const Duration(days: 7));
    for (final meeting in meetings) {
      await _postponeUnprocessedMeeting(context, meeting, nextWeek);
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 390,
        maxHeight: MediaQuery.sizeOf(context).height - 100,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: appBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appBorderStrong),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FutureBuilder<List<Contact>>(
          future: _meetingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(22),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final meetings = snapshot.data ?? [];
            if (meetings.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Powiadomienia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Zamknij',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nie masz nierozliczonych spotkań.',
                      style: TextStyle(color: appTextSecondary),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nierozliczone spotkania (${meetings.length})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Zamknij',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _postponeAllNextWeek(meetings),
                    icon: const Icon(Icons.update_outlined),
                    label: const Text('Przenieś wszystkie na przyszły tydzień'),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var index = 0; index < meetings.length; index++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: index == meetings.length - 1 ? 0 : 8,
                              ),
                              child: _UnprocessedMeetingDecisionTile(
                                contact: meetings[index],
                                onChanged: _reload,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UnprocessedMeetingDecisionTile extends StatelessWidget {
  const _UnprocessedMeetingDecisionTile({
    required this.contact,
    required this.onChanged,
  });

  final Contact contact;
  final Future<void> Function() onChanged;

  String get _timeText {
    if (contact.contactTime.length >= 5) {
      return contact.contactTime.substring(0, 5);
    }
    return contact.contactTime.isEmpty ? '--:--' : contact.contactTime;
  }

  String get _dateText {
    if (contact.contactDate == null) return 'Bez daty';
    return '${_shortDate(contact.contactDate!)} | ${_weekdayNameFull(contact.contactDate!)}';
  }

  Future<void> _run(Future<void> Function() action) async {
    await action();
    await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: appBrandSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _timeText,
                  style: const TextStyle(
                    color: appBrand,
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
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _dateText,
            style: const TextStyle(
              color: appTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _DecisionChip(
                label: 'Sprzedane',
                color: appSuccess,
                onTap: () =>
                    _run(() => _sellUnprocessedMeeting(context, contact)),
              ),
              _DecisionChip(
                label: 'Nie sprzedane',
                color: const Color(0xFFF0A202),
                onTap: () => _run(() async {
                  await showContactDetailsSheet(context, contact);
                }),
              ),
              _DecisionChip(
                label: 'Przełóż',
                color: appInfo,
                onTap: () => _run(
                  () => _postponeUnprocessedMeetingWithPicker(context, contact),
                ),
              ),
              _DecisionChip(
                label: 'Do kontaktu',
                color: appBrand,
                onTap: () => _run(
                  () => _returnUnprocessedMeetingToContact(context, contact),
                ),
              ),
              _DecisionChip(
                label: 'Usuń',
                color: appDanger,
                onTap: () =>
                    _run(() => _deleteUnprocessedMeeting(context, contact)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionChip extends StatelessWidget {
  const _DecisionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _sellUnprocessedMeeting(
  BuildContext context,
  Contact contact,
) async {
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
      .update({
        'status': 'signed_contract',
        'moved_to_client_at': DateTime.now().toIso8601String(),
        'note': _mergeContactNote(
          contact.note,
          'Wynik spotkania: spisana umowa. Przeniesiono do W realizacji.',
        ),
      })
      .eq('id', contact.id);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('Przeniesiono do W realizacji.')),
    );
}

Future<void> _postponeUnprocessedMeetingWithPicker(
  BuildContext context,
  Contact contact,
) async {
  final selected = await showDialog<DateTime>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Na kiedy przełożyć?'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(
            context,
            DateTime.now().add(const Duration(days: 1)),
          ),
          child: const Text('Jutro'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(
            context,
            DateTime.now().add(const Duration(days: 7)),
          ),
          child: const Text('Za tydzień'),
        ),
        SimpleDialogOption(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (context.mounted) Navigator.pop(context, picked);
          },
          child: const Text('Własna data'),
        ),
      ],
    ),
  );

  if (selected == null) return;
  if (!context.mounted) return;
  await _postponeUnprocessedMeeting(context, contact, selected);
}

Future<void> _postponeUnprocessedMeeting(
  BuildContext context,
  Contact contact,
  DateTime date,
) async {
  await _supabase
      .from('contacts')
      .update({
        'status': 'scheduled_meeting',
        'contact_date': _dateOnly(date),
        'contact_time': contact.contactTime.isEmpty
            ? '18:00:00'
            : contact.contactTime,
        'meeting_time': contact.contactTime.isEmpty
            ? '18:00:00'
            : contact.contactTime,
        'contact_notification': null,
        'note': _mergeContactNote(
          contact.note,
          'Przełożone na ${_shortDate(date)} (${_weekdayName(date)}).',
        ),
      })
      .eq('id', contact.id);
}

Future<void> _returnUnprocessedMeetingToContact(
  BuildContext context,
  Contact contact,
) async {
  final statuses = _statusesForStage('contact');
  final selected = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Jaki status kontaktu?'),
      children: [
        for (final status in statuses)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, status.value),
            child: Text(status.label),
          ),
      ],
    ),
  );
  if (selected == null) return;

  await _supabase
      .from('contacts')
      .update({
        'status': 'contact',
        'contact_status': selected,
        'contact_date': null,
        'contact_time': null,
        'meeting_time': null,
        'contact_notification': null,
        'note': _mergeContactNote(
          contact.note,
          'Nierozliczone spotkanie przeniesione do kontaktów.',
        ),
      })
      .eq('id', contact.id);
}

Future<void> _deleteUnprocessedMeeting(
  BuildContext context,
  Contact contact,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Usunąć spotkanie?'),
      content: const Text('Ten kontakt zostanie usunięty na stałe.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: appDanger),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Usuń'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  await _supabase.from('contacts').delete().eq('id', contact.id);
}

String _mergeContactNote(String currentNote, String addition) {
  final trimmed = currentNote.trim();
  if (trimmed.isEmpty) return addition;
  return '$trimmed\n$addition';
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
  String? _contactWorkStatus;
  final List<String> _contactTypes = [];
  DateTime _contactDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _contactTime = const TimeOfDay(hour: 18, minute: 0);
  String? _contactQuality;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initialStage = _stageForContactStatus(widget.initialStatus);
    final stageStatuses = _statusesForStage(initialStage);
    _status = initialStage == 'contact'
        ? 'contact'
        : stageStatuses.any((status) => status.value == widget.initialStatus)
        ? widget.initialStatus
        : stageStatuses.first.value;
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
        'status': _stageForContactStatus(_status) == 'contact'
            ? 'contact'
            : _status,
        'contact_status': _stageForContactStatus(_status) == 'contact'
            ? _contactWorkStatus
            : null,
        'note': _noteController.text.trim(),
      };

      if (_stageForContactStatus(_status) == 'meeting') {
        payload.addAll({
          'contact_date': _dateOnly(_contactDate),
          'contact_time': _timeOnly(_contactTime),
          'meeting_time': _timeOnly(_contactTime),
          'contact_quality': _contactQuality,
        });
      }

      if (_contactTypes.isNotEmpty) {
        payload['contact_type'] = _contactTypeValuesToRaw(_contactTypes);
      }

      await _insertContactPayload(payload);

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

  Future<void> _insertContactPayload(Map<String, dynamic> payload) async {
    try {
      await _supabase.from('contacts').insert(payload);
    } on PostgrestException catch (error) {
      final canRetryWithoutContactType =
          payload.containsKey('contact_type') &&
          _isMissingContactTypeColumnError(error);
      if (!canRetryWithoutContactType) rethrow;

      final fallbackPayload = Map<String, dynamic>.from(payload)
        ..remove('contact_type');
      await _supabase.from('contacts').insert(fallbackPayload);
    }
  }

  bool _isMissingContactTypeColumnError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return message.contains('contact_type') &&
        (message.contains('column') || message.contains('schema cache'));
  }

  Future<bool> _contactPhoneExists(String agentId, String phone) async {
    final normalizedPhone = _normalizePhone(phone);
    final data = await _supabase
        .from('contacts')
        .select('id, phone')
        .eq('agent_id', agentId)
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
    return _stageForContactStatus(_status) == 'meeting'
        ? 'Umów spotkanie'
        : 'Dodaj kontakt';
  }

  String get _statusStage => _stageForContactStatus(_status);

  Future<void> _pickContactType() async {
    final picked = await _showContactTypePicker(
      context,
      value: _contactTypes.isEmpty ? '' : _contactTypes.first,
    );
    if (picked == null) return;
    setState(() {
      _contactTypes
        ..clear()
        ..add(picked.value);
    });
  }

  void _toggleContactType(ContactStatus type) {
    setState(() {
      if (_contactTypes.contains(type.value)) {
        _contactTypes.remove(type.value);
        return;
      }
      if (_contactTypes.length >= 3) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Możesz wybrać maksymalnie 3 typy.')),
          );
        return;
      }
      _contactTypes.add(type.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isMeetingForm = _statusStage == 'meeting';

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
                  _ContactStatusPill(
                    status:
                        _contactTypes.isNotEmpty &&
                            _statusesForStage(
                              'contact_type',
                            ).any((type) => type.value == _contactTypes.first)
                        ? _statusByValue(_contactTypes.first)
                        : _defaultContactTypeStatus,
                    onTap: _pickContactType,
                  ),
                  IconButton(
                    tooltip: 'Zamknij',
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Imię i nazwisko'),
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
              const SizedBox(height: 12),
              _ContactTypeSelector(
                selectedValues: _contactTypes,
                onToggle: _toggleContactType,
                onOpenSettings: () =>
                    _pushSettingsSubpage(context, const ContactStatusesPage()),
              ),
              const SizedBox(height: 12),
              if (!isMeetingForm) ...[
                _StatusPickerField(
                  stage: 'contact',
                  value: _contactWorkStatus,
                  onChanged: (value) =>
                      setState(() => _contactWorkStatus = value),
                ),
              ],
              if (isMeetingForm) ...[
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
                  if (_statusStage == 'meeting' && address.isEmpty) {
                    return 'Umówione spotkanie musi mieć adres.';
                  }
                  if (_statusStage == 'contact' &&
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
                      ? (_statusStage == 'meeting'
                            ? 'Umawiam...'
                            : 'Zapisuję...')
                      : (_statusStage == 'meeting'
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
            const DropdownMenuItem(value: null, child: Text('?')),
            for (final item in _qualities)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: onQualityChanged,
        ),
      ],
    );
  }
}
