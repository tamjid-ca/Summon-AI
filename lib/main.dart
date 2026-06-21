import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:summon_ai/firebase_options.dart';
import 'package:summon_ai/service/auth_service.dart';
import 'package:summon_ai/service/user_data_service.dart';
import 'package:summon_ai/view/gemini_chat_view.dart';
import 'package:summon_ai/view/summon_ai_view.dart';
import 'package:summon_ai/view/weather_view.dart';
import 'package:summon_ai/view_model/ai_view_model.dart';
import 'package:summon_ai/view_model/chat_view_model.dart';
import 'package:summon_ai/view_model/weather_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final firebaseReady = await _initializeFirebase();
  runApp(MyApp(firebaseReady: firebaseReady));
}

Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on UnsupportedError {
    return false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Summon AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7B2FBE),
          secondary: Color(0xFF4776E6),
          surface: Color(0xFF1A1A35),
        ),
        useMaterial3: true,
      ),
      home: firebaseReady ? const AuthGate() : const FirebaseSetupView(),
    );
  }
}

class FirebaseSetupView extends StatelessWidget {
  const FirebaseSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_rounded, color: Color(0xFF4776E6), size: 56),
                SizedBox(height: 18),
                Text(
                  'Firebase setup required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Run "flutterfire configure" from the project root to generate real Firebase options, then run the app again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFB0B0C8),
                    height: 1.5,
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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  bool _isSigningIn = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    try {
      final credential = await _authService.signInWithGoogle();
      final user = credential.user;
      if (user != null) {
        // The profile document keeps account metadata separate from app data.
        // Feature data lives in subcollections under this user document.
        await UserDataService().saveUserProfile(user);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return _RootShell(user: user, authService: _authService);
        }

        return _SignInView(
          isSigningIn: _isSigningIn,
          errorMessage: _errorMessage,
          onSignIn: _signIn,
        );
      },
    );
  }
}

class _SignInView extends StatelessWidget {
  const _SignInView({
    required this.isSigningIn,
    required this.errorMessage,
    required this.onSignIn,
  });

  final bool isSigningIn;
  final String? errorMessage;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2FBE), Color(0xFF4776E6)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Summon AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to save your jokes and weather searches to your own account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFFF6B8A)),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: isSigningIn ? null : onSignIn,
                  icon: isSigningIn
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(isSigningIn ? 'Signing in...' : 'Sign in with Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell({required this.user, required this.authService});

  final User user;
  final AuthService authService;

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _currentIndex = 0;
  bool _isChatOpen = false;

  late final AIViewModel _aiViewModel = AIViewModel()..loadUserHistory();
  late final ChatViewModel _chatViewModel = ChatViewModel();
  late final WeatherViewModel _weatherViewModel =
      WeatherViewModel()..loadUserHistory();

  static const _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.auto_awesome_rounded),
      activeIcon: Icon(Icons.auto_awesome),
      label: 'Jokes',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.wb_cloudy_outlined),
      activeIcon: Icon(Icons.wb_cloudy_rounded),
      label: 'Weather',
    ),
  ];

  @override
  void dispose() {
    _aiViewModel.dispose();
    _chatViewModel.dispose();
    _weatherViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              SummonAIView(
                viewModel: _aiViewModel,
                user: widget.user,
                onSignOut: widget.authService.signOut,
              ),
              WeatherView(
                viewModel: _weatherViewModel,
                user: widget.user,
                onSignOut: widget.authService.signOut,
              ),
            ],
          ),
          if (_isChatOpen)
            Positioned.fill(
              child: GeminiChatPanel(
                viewModel: _chatViewModel,
                onClose: () => setState(() => _isChatOpen = false),
              ),
            ),
          if (!_isChatOpen)
            Positioned(
              right: 18,
              bottom: 18,
              child: FloatingActionButton.extended(
                onPressed: () => setState(() => _isChatOpen = true),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Chat'),
                backgroundColor: const Color(0xFF4776E6),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isChatOpen
          ? null
          : _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.07), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF4776E6),
        unselectedItemColor: const Color(0xFF6B6B8A),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: _navItems,
      ),
    );
  }
}
