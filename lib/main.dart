import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:summon_ai/view/summon_ai_view.dart';
import 'package:summon_ai/view/weather_view.dart';
import 'package:summon_ai/view/gemini_chat_overlay.dart';
import 'package:summon_ai/view_model/ai_view_model.dart';
import 'package:summon_ai/view_model/weather_view_model.dart';
import 'package:summon_ai/view_model/gemini_chat_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const _RootShell(),
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _currentIndex = 0;
  bool _isChatOpen = false;

  final AIViewModel _aiViewModel = AIViewModel();
  final WeatherViewModel _weatherViewModel = WeatherViewModel();
  final GeminiChatViewModel _chatViewModel = GeminiChatViewModel();

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
    _weatherViewModel.dispose();
    _chatViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0D0D1A),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              SummonAIView(viewModel: _aiViewModel),
              WeatherView(viewModel: _weatherViewModel),
            ],
          ),
          bottomNavigationBar: _buildNavBar(),
          floatingActionButton: _isChatOpen
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _isChatOpen = true;
                    });
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  highlightElevation: 0,
                  focusElevation: 0,
                  hoverElevation: 0,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B2FBE), Color(0xFF4776E6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B2FBE).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
        if (_isChatOpen)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: GeminiChatOverlay(
                viewModel: _chatViewModel,
                onClose: () {
                  setState(() {
                    _isChatOpen = false;
                  });
                },
              ),
            ),
          ),
      ],
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