import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'providers/wordlist_provider.dart';
import 'providers/test_provider.dart';
import 'screens/pin_setup_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'screens/main_screen.dart';
import 'screens/wordlist_view_screen.dart';
import 'screens/flashcard_screen.dart';
import 'screens/test_screen.dart';
import 'screens/test_summary_screen.dart';
import 'screens/results_history_screen.dart';
import 'screens/result_detail_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/wordlist_create_screen.dart';
import 'screens/settings/wordlist_edit_screen.dart';
import 'screens/settings/change_pin_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SnazzySpellingApp());
}

class SnazzySpellingApp extends StatelessWidget {
  const SnazzySpellingApp({super.key});

  static ThemeData _buildTheme(Brightness brightness) {
    const seedColor = Color(0xFF7B5EA7);
    const interTextTheme = TextTheme(
      displayLarge: TextStyle(fontFamily: 'Inter'),
      displayMedium: TextStyle(fontFamily: 'Inter'),
      displaySmall: TextStyle(fontFamily: 'Inter'),
      headlineLarge: TextStyle(fontFamily: 'Inter'),
      headlineMedium: TextStyle(fontFamily: 'Inter'),
      headlineSmall: TextStyle(fontFamily: 'Inter'),
      titleLarge: TextStyle(fontFamily: 'Inter'),
      titleMedium: TextStyle(fontFamily: 'Inter'),
      titleSmall: TextStyle(fontFamily: 'Inter'),
      bodyLarge: TextStyle(fontFamily: 'Inter'),
      bodyMedium: TextStyle(fontFamily: 'Inter'),
      bodySmall: TextStyle(fontFamily: 'Inter'),
      labelLarge: TextStyle(fontFamily: 'Inter'),
      labelMedium: TextStyle(fontFamily: 'Inter'),
      labelSmall: TextStyle(fontFamily: 'Inter'),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      contrastLevel: 0.5,
    );

    return ThemeData(
      colorScheme: colorScheme,
      fontFamily: 'Inter',
      textTheme: interTextTheme,
      useMaterial3: true,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => WordlistProvider()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Snazzy Spelling',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: settings.themeMode,
            home: const _AppBootstrap(),
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/pin-setup':
        return MaterialPageRoute(
          builder: (_) => const PinSetupScreen(),
        );
      case '/pin-entry':
        final destination = settings.arguments as String? ?? '/settings';
        return MaterialPageRoute(
          builder: (_) => PinEntryScreen(destination: destination),
        );
      case '/main':
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
        );
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
      case '/settings/wordlist/create':
        final firstLaunch = settings.arguments as bool? ?? false;
        return MaterialPageRoute(
          builder: (_) => WordlistCreateScreen(firstLaunch: firstLaunch),
        );
      case '/settings/wordlist/edit':
        final id = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => WordlistEditScreen(wordlistId: id),
        );
      case '/settings/change-pin':
        return MaterialPageRoute(
          builder: (_) => const ChangePinScreen(),
        );
      case '/wordlist/view':
        final id = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => WordlistViewScreen(wordlistId: id),
        );
      case '/wordlist/flashcards':
        final id = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => FlashcardScreen(wordlistId: id),
        );
      case '/wordlist/test':
        final id = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => TestScreen(wordlistId: id),
        );
      case '/wordlist/test-summary':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => TestSummaryScreen(
            wordlistId: args['wordlistId'] as int,
            sessionId: args['sessionId'] as int,
            wordlistName: args['wordlistName'] as String,
          ),
        );
      case '/wordlist/results':
        final id = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ResultsHistoryScreen(wordlistId: id),
        );
      case '/wordlist/result-detail':
        final id = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ResultDetailScreen(sessionId: id),
        );
      default:
        return null;
    }
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final settings = context.read<SettingsProvider>();
    final wordlists = context.read<WordlistProvider>();
    await settings.load();
    await wordlists.load();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, WordlistProvider>(
      builder: (context, settings, wordlists, _) {
        if (!settings.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!settings.hasPinSet) {
          return const PinSetupScreen();
        }

        return const MainScreen();
      },
    );
  }
}
