import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';
import 'services/database_service.dart';
import 'services/database_test_service.dart';
import 'providers/theme_provider.dart';
import 'providers/localization_provider.dart';
import 'providers/font_size_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/disease_detection_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/soil_provider.dart';
import 'providers/location_provider.dart';
import 'providers/my_crops_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize database factory for desktop platforms
  await DatabaseService.initializeDatabaseFactory();

  // Initialize database service
  await DatabaseService.instance.initialize();

  // Run database test
  final testService = DatabaseTestService();
  await testService.testDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        ChangeNotifierProvider(create: (_) => FontSizeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DiseaseDetectionProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => SoilProvider()),
        ChangeNotifierProvider(create: (_) => MyCropsProvider()),
      ],
      child: Consumer3<ThemeProvider, LocalizationProvider, FontSizeProvider>(
        builder:
            (
              context,
              themeProvider,
              localizationProvider,
              fontSizeProvider,
              child,
            ) {
              // Determine font family based on locale
              final fontFamily =
                  localizationProvider.locale.languageCode == 'bn'
                  ? 'NotoSansBengali'
                  : null;

              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'AgriBase',
                theme: ThemeData(
                  colorScheme:
                      ColorScheme.fromSeed(
                        seedColor: const Color.fromARGB(255, 0, 77, 64),
                        brightness: Brightness.light,
                      ).copyWith(
                        primary: const Color.fromARGB(255, 0, 77, 64),
                        secondary: const Color.fromARGB(255, 76, 175, 80),
                      ),
                  useMaterial3: true,
                  fontFamily: fontFamily,
                  scaffoldBackgroundColor: Colors.white,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color.fromARGB(255, 0, 77, 64),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  textTheme: ThemeData.light().textTheme
                      .apply(
                        bodyColor: Colors.black87,
                        displayColor: Colors.black87,
                      )
                      .copyWith(
                        bodyLarge: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontFamily: fontFamily,
                          color: Colors.black87,
                        ),
                        bodyMedium: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontFamily: fontFamily,
                          color: Colors.black87,
                        ),
                        bodySmall: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 2,
                          fontFamily: fontFamily,
                          color: Colors.black87,
                        ),
                        headlineLarge: TextStyle(
                          fontSize: fontSizeProvider.fontSize + 4,
                          fontFamily: fontFamily,
                          color: Colors.black87,
                        ),
                        headlineMedium: TextStyle(
                          fontSize: fontSizeProvider.fontSize + 2,
                          fontFamily: fontFamily,
                          color: Colors.black87,
                        ),
                        headlineSmall: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontFamily: fontFamily,
                          color: Colors.black87,
                        ),
                        titleLarge: TextStyle(
                          fontSize: fontSizeProvider.fontSize + 2,
                          fontFamily: fontFamily,
                          color: Colors.black87,
                        ),
                        titleMedium: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontFamily: fontFamily,
                          color: Colors.black87,
                        ),
                        titleSmall: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 2,
                          fontFamily: fontFamily,
                          color: Colors.black87,
                        ),
                        labelLarge: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontFamily: fontFamily,
                          color: Colors.black87,
                        ),
                        labelMedium: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 1,
                          fontFamily: fontFamily,
                          color: Colors.black87,
                        ),
                        labelSmall: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 2,
                          fontFamily: fontFamily,
                          color: Colors.black87,
                        ),
                      ),
                ),
                darkTheme: ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: const Color.fromARGB(255, 0, 109, 91),
                    secondary: const Color.fromARGB(255, 76, 175, 80),
                    surface: const Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                    onPrimary: Colors.white,
                    surfaceContainerHighest: const Color(0xFF2A2A2A),
                    onSurfaceVariant: Colors.white70,
                    error: Colors.red[400]!,
                    onError: Colors.white,
                  ),
                  scaffoldBackgroundColor: const Color(0xFF121212),
                  cardColor: const Color(0xFF2A2A2A),
                  dividerColor: Colors.white24,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color.fromARGB(255, 0, 77, 64),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  textTheme: ThemeData.dark().textTheme
                      .apply(
                        bodyColor: Colors.white,
                        displayColor: Colors.white,
                      )
                      .copyWith(
                        bodyLarge: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontFamily: fontFamily,
                          color: Colors.white,
                        ),
                        bodyMedium: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontFamily: fontFamily,
                          color: Colors.white,
                        ),
                        bodySmall: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 2,
                          fontFamily: fontFamily,
                          color: Colors.white70,
                        ),
                        headlineLarge: TextStyle(
                          fontSize: fontSizeProvider.fontSize + 4,
                          fontFamily: fontFamily,
                          color: Colors.white,
                        ),
                        headlineMedium: TextStyle(
                          fontSize: fontSizeProvider.fontSize + 2,
                          fontFamily: fontFamily,
                          color: Colors.white,
                        ),
                        headlineSmall: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontFamily: fontFamily,
                          color: Colors.white,
                        ),
                        titleLarge: TextStyle(
                          fontSize: fontSizeProvider.fontSize + 2,
                          fontFamily: fontFamily,
                          color: Colors.white,
                        ),
                        titleMedium: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontFamily: fontFamily,
                          color: Colors.white,
                        ),
                        titleSmall: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 2,
                          fontFamily: fontFamily,
                          color: Colors.white70,
                        ),
                        labelLarge: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontFamily: fontFamily,
                          color: Colors.white,
                        ),
                        labelMedium: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 1,
                          fontFamily: fontFamily,
                          color: Colors.white70,
                        ),
                        labelSmall: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 2,
                          fontFamily: fontFamily,
                          color: Colors.white70,
                        ),
                      ),
                ),
                themeMode: themeProvider.themeMode,
                localizationsDelegates: [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('en', ''), Locale('bn', '')],
                locale: localizationProvider.locale,
                home: const AuthWrapper(),
              );
            },
      ),
    );
  }
}
