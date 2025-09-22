import 'package:agribot/Screens/bottom_navigation.dart';
import 'package:agribot/Screens/home_screen.dart';
import 'package:agribot/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agribot/Screens/first_screen.dart';
import 'package:agribot/Providers/weather_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Use the generated list so it always matches your ARBs:
      supportedLocales: AppLocalizations.supportedLocales,
      // Optional: log/handle resolution
      localeResolutionCallback: (deviceLocale, supported) {
        // Log what’s going on while debugging:
        // debugPrint('device: $deviceLocale, supported: $supported');
        if (deviceLocale == null) return supported.first;
        for (final s in supported) {
          if (s.languageCode == deviceLocale.languageCode) return s;
        }
        return const Locale('en');
      },
      home: FirstScreen(onChangeLanguage: _setLocale),
    );
  }
}
