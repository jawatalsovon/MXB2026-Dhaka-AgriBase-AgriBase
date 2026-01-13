import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'calculator_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/soil_provider.dart';
import '../providers/location_provider.dart';
import '../utils/translations.dart';
import '../widgets/weather_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _dailyInsights = [];
  int _currentInsightIndex = 0;
  bool _insightsLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );
      final soilProvider = Provider.of<SoilProvider>(context, listen: false);

      // Get location
      await locationProvider.requestLocation();

      debugPrint(
        'Location obtained: ${locationProvider.latitude}, ${locationProvider.longitude}',
      );

      if (locationProvider.latitude != null &&
          locationProvider.longitude != null) {
        // Fetch weather and soil data
        final lat = locationProvider.latitude!;
        final lon = locationProvider.longitude!;
        final locationName = locationProvider.districtName ?? 'Location';

        debugPrint('Fetching weather for: $lat, $lon (Name: $locationName)');

        await Future.wait([
          weatherProvider.fetchWeather(lat, lon, locationName: locationName),
          soilProvider.fetchSoil(lat, lon),
        ]);

        debugPrint(
          'Weather temp: ${weatherProvider.weatherData?.currentTemp}°C',
        );

        // Generate AI insights
        await _generateInsights();
      } else {
        debugPrint('Location not obtained, using defaults');
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _insightsLoading = false;
        });
      }
    }
  }

  Future<void> _generateInsights() async {
    try {
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );
      final soilProvider = Provider.of<SoilProvider>(context, listen: false);
      final insights = <Map<String, dynamic>>[];

      final weather = weatherProvider.weatherData;
      final soil = soilProvider.soilData;

      debugPrint('Generating insights...');
      debugPrint('Weather data: $weather');
      debugPrint('Weather currentTemp: ${weather?.currentTemp}');
      debugPrint('Soil data: $soil');

      // Weather-based insights
      if (weather != null && weather.dailyForecasts.isNotEmpty) {
        final today = weather.dailyForecasts.first;

        // High precipitation alert
        if (today.precipitationProbability > 70) {
          insights.add({
            'icon': Icons.water_drop,
            'color': Colors.blue,
            'title': 'High Rainfall Expected',
            'message':
                '${today.precipitationProbability}% chance of rain today. Delay spraying operations.',
            'severity': 'warning',
          });
        }

        // Temperature-based insight
        if (today.maxTemp > 32) {
          insights.add({
            'icon': Icons.wb_sunny,
            'color': Colors.orange,
            'title': 'Heat Alert',
            'message':
                'High temperature (${today.maxTemp.toStringAsFixed(1)}°C). Ensure adequate irrigation.',
            'severity': 'warning',
          });
        } else if (today.maxTemp > 25 && today.maxTemp < 30) {
          insights.add({
            'icon': Icons.wb_sunny,
            'color': Colors.green,
            'title': 'Optimal Growing Conditions',
            'message':
                'Temperature range ideal for most crops. Good time for field activities.',
            'severity': 'tip',
          });
        }

        // Wind speed alert
        if (today.windSpeed > 15) {
          insights.add({
            'icon': Icons.air,
            'color': Colors.orange,
            'title': 'High Wind Alert',
            'message':
                'Wind speed ${today.windSpeed.toStringAsFixed(1)} km/h. Avoid pesticide spraying.',
            'severity': 'warning',
          });
        }
      }

      // Soil-based insights
      if (soil != null) {
        if (soil.ph < 6.0) {
          insights.add({
            'icon': Icons.eco,
            'color': Colors.red,
            'title': 'Acidic Soil Detected',
            'message':
                'pH ${soil.ph.toStringAsFixed(1)} - Consider lime application to raise pH.',
            'severity': 'warning',
          });
        } else if (soil.ph > 7.8) {
          insights.add({
            'icon': Icons.eco,
            'color': Colors.amber,
            'title': 'Alkaline Soil',
            'message':
                'pH ${soil.ph.toStringAsFixed(1)} - Sulfur addition may help lower pH.',
            'severity': 'warning',
          });
        } else {
          insights.add({
            'icon': Icons.eco,
            'color': Colors.green,
            'title': 'Optimal Soil pH',
            'message':
                'pH ${soil.ph.toStringAsFixed(1)} - Ideal range for most crops.',
            'severity': 'tip',
          });
        }

        if (soil.organicCarbon < 1.0) {
          insights.add({
            'icon': Icons.compost,
            'color': Colors.brown,
            'title': 'Low Organic Matter',
            'message':
                'Consider adding compost to improve soil fertility and water retention.',
            'severity': 'tip',
          });
        }
      }

      // Default insight if no data available
      if (insights.isEmpty) {
        insights.add({
          'icon': Icons.tips_and_updates,
          'color': Colors.blue,
          'title': 'Welcome to AgriBase',
          'message':
              'Enable location access to get personalized farming insights.',
          'severity': 'info',
        });
      }

      if (mounted) {
        setState(() {
          _dailyInsights = insights;
          _currentInsightIndex = 0;
        });
        debugPrint('Insights generated: ${insights.length} insights');
      }
    } catch (e) {
      debugPrint('Error generating insights: $e');
      if (mounted) {
        setState(() {
          _dailyInsights = [
            {
              'icon': Icons.error,
              'color': Colors.red,
              'title': 'Error Loading Data',
              'message':
                  'Failed to load insights. Please check your location and try again.',
              'severity': 'warning',
            },
          ];
          _currentInsightIndex = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer5<
      AuthProvider,
      LocalizationProvider,
      WeatherProvider,
      SoilProvider,
      LocationProvider
    >(
      builder:
          (
            context,
            authProvider,
            localizationProvider,
            weatherProvider,
            soilProvider,
            locationProvider,
            child,
          ) {
            final isAuthenticated = authProvider.isAuthenticated;
            final locale = localizationProvider.locale;
            final theme = Theme.of(context);
            final isBangla = locale.languageCode == 'bn';

            return Scaffold(
              appBar: AppBar(
                backgroundColor: theme.colorScheme.primary,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(Icons.menu, color: theme.colorScheme.onPrimary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const SettingsScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.ease;
                              var tween = Tween(
                                begin: begin,
                                end: end,
                              ).chain(CurveTween(curve: curve));
                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                      ),
                    );
                  },
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.eco,
                      color: theme.colorScheme.onPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "AgriBase",
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (isAuthenticated)
                    IconButton(
                      icon: Icon(
                        Icons.logout,
                        color: theme.colorScheme.onPrimary,
                      ),
                      onPressed: () =>
                          _showSignOutDialog(context, authProvider),
                    ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section with greeting
                    _buildHeroSection(
                      context,
                      isAuthenticated,
                      locale,
                      authProvider,
                    ),

                    // Daily Insight Widget (AI-powered tip)
                    if (_insightsLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_dailyInsights.isNotEmpty)
                      _buildDailyInsightCard(context, isBangla),

                    // System Status Badges
                    _buildStatusBadges(
                      context,
                      isBangla,
                      weatherProvider,
                      soilProvider,
                      locationProvider,
                    ),

                    // Weather widget (only for authenticated users)
                    if (isAuthenticated)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: WeatherWidget(),
                      ),

                    // Quick Actions Grid
                    _buildQuickActionsSection(context, isBangla),

                    // App Overview Section
                    _buildAppOverviewSection(context),

                    // Contact Section
                    _buildContactSection(context),
                  ],
                ),
              ),
            );
          },
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    bool isAuthenticated,
    Locale locale,
    AuthProvider authProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 0, 77, 64),
            Color.fromARGB(255, 76, 175, 80),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAuthenticated
                ? '${Translations.translate(locale, 'helloUser')} ${authProvider.username ?? 'User'}'
                : Translations.translate(locale, 'welcomeToAgriBase'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Translations.translate(locale, 'appDescription'),
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (!isAuthenticated)
            ElevatedButton.icon(
              onPressed: () => _showAuthPrompt(context),
              icon: const Icon(Icons.login),
              label: Text(
                Translations.translate(locale, 'signInForEnhancedFeatures'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDailyInsightCard(BuildContext context, bool isBangla) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final insight = _dailyInsights[_currentInsightIndex];

    Color bgColor;
    Color borderColor;
    switch (insight['severity']) {
      case 'warning':
        bgColor = Colors.amber.withValues(alpha: 0.1);
        borderColor = Colors.amber;
        break;
      case 'tip':
        bgColor = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green;
        break;
      default:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        borderColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (insight['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    insight['icon'] as IconData,
                    color: insight['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: const Color(0xFF1A237E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBangla ? 'দৈনিক ইনসাইট' : 'Daily Insight',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF1A237E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        insight['title'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 20),
                  onPressed: () {
                    setState(() {
                      _currentInsightIndex =
                          (_currentInsightIndex + 1) % _dailyInsights.length;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight['message'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadges(
    BuildContext context,
    bool isBangla,
    WeatherProvider weatherProvider,
    SoilProvider soilProvider,
    LocationProvider locationProvider,
  ) {
    final theme = Theme.of(context);
    final weather = weatherProvider.weatherData;
    final soil = soilProvider.soilData;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Name
          if (locationProvider.districtName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                '📍 ${locationProvider.districtName}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            isBangla ? 'সিস্টেম স্ট্যাটাস' : 'System Status',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Weather Status
                if (weather != null && weather.dailyForecasts.isNotEmpty)
                  _buildStatusChip(
                    context,
                    Icons.cloud,
                    isBangla ? 'আবহাওয়া' : 'Weather',
                    weather.dailyForecasts.first.getWeatherDescription(),
                    _getWeatherColor(weather.dailyForecasts.first.weatherCode),
                  ),
                const SizedBox(width: 8),
                // Soil Moisture (based on soil type)
                if (soil != null)
                  _buildStatusChip(
                    context,
                    Icons.water,
                    isBangla ? 'মাটির ধরণ' : 'Soil Type',
                    soil.soilType,
                    Colors.green,
                  ),
                const SizedBox(width: 8),
                // Pest Risk (based on weather)
                if (weather != null && weather.dailyForecasts.isNotEmpty)
                  _buildStatusChip(
                    context,
                    Icons.bug_report,
                    isBangla ? 'কীট ঝুঁকি' : 'Pest Risk',
                    _getPestRisk(weather.dailyForecasts.first, isBangla),
                    _getPestRiskColor(weather.dailyForecasts.first),
                  ),
                const SizedBox(width: 8),
                // Temperature
                if (weather?.currentTemp != null && weather!.currentTemp! != 0)
                  _buildStatusChip(
                    context,
                    Icons.thermostat,
                    isBangla ? 'তাপমাত্রা' : 'Temperature',
                    '${weather.currentTemp!.toStringAsFixed(1)}°C',
                    _getTempColor(weather.currentTemp!),
                  )
                else if (weather?.dailyForecasts.isNotEmpty ?? false)
                  _buildStatusChip(
                    context,
                    Icons.thermostat,
                    isBangla ? 'তাপমাত্রা' : 'Temperature',
                    '${((weather!.dailyForecasts.first.maxTemp + weather.dailyForecasts.first.minTemp) / 2).toStringAsFixed(1)}°C',
                    _getTempColor(
                      (weather.dailyForecasts.first.maxTemp +
                              weather.dailyForecasts.first.minTemp) /
                          2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getWeatherColor(int weatherCode) {
    if (weatherCode >= 61 && weatherCode <= 67) return Colors.blue; // Rain
    if (weatherCode >= 71 && weatherCode <= 77) return Colors.blueGrey; // Snow
    if (weatherCode >= 95 && weatherCode <= 99) {
      return Colors.red; // Thunderstorm
    }
    return Colors.green; // Clear/Cloudy
  }

  String _getPestRisk(dynamic forecast, bool isBangla) {
    final temp = forecast.maxTemp;
    final precip = forecast.precipitationProbability;

    if (temp > 28 && precip > 60) {
      return isBangla ? 'উচ্চ' : 'High';
    } else if (temp > 25 && precip > 40) {
      return isBangla ? 'মাঝারি' : 'Medium';
    }
    return isBangla ? 'নিম্ন' : 'Low';
  }

  Color _getPestRiskColor(dynamic forecast) {
    final temp = forecast.maxTemp;
    final precip = forecast.precipitationProbability;

    if (temp > 28 && precip > 60) return Colors.red;
    if (temp > 25 && precip > 40) return Colors.orange;
    return Colors.green;
  }

  Color _getTempColor(double temp) {
    if (temp > 35) return Colors.red;
    if (temp > 30) return Colors.orange;
    if (temp < 15) return Colors.blue;
    return Colors.green;
  }

  Widget _buildStatusChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, bool isBangla) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                isBangla ? 'দ্রুত কার্যক্রম' : 'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              _buildQuickActionTile(
                context,
                Icons.calculate,
                isBangla ? 'সার' : 'Fertilizer',
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CalculatorScreen(mode: 'fertilizer'),
                  ),
                ),
              ),
              _buildQuickActionTile(
                context,
                Icons.grain,
                isBangla ? 'বীজ' : 'Seed',
                Colors.amber.shade700,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CalculatorScreen(mode: 'seed'),
                  ),
                ),
              ),
              _buildQuickActionTile(
                context,
                Icons.psychology,
                isBangla ? 'AI হাব' : 'AI Hub',
                const Color(0xFF1A237E),
                () {
                  // Navigate to AI Hub tab
                  // This will be handled by parent navigation
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppOverviewSection(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localizationProvider, child) {
        final locale = localizationProvider.locale;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(24.0),
          color: isDark ? theme.colorScheme.surface : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translations.translate(locale, 'whatAgribaseOffers'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              _buildOverviewCard(
                context: context,
                locale: locale,
                icon: Icons.psychology,
                titleKey: 'smartAnalytics',
                descKey: 'smartAnalyticsDesc',
              ),
              const SizedBox(height: 12),
              _buildOverviewCard(
                context: context,
                locale: locale,
                icon: Icons.map,
                titleKey: 'regionalInsights',
                descKey: 'regionalInsightsDesc',
              ),
              const SizedBox(height: 12),
              _buildOverviewCard(
                context: context,
                locale: locale,
                icon: Icons.eco,
                titleKey: 'sustainablePractices',
                descKey: 'sustainablePracticesDesc',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard({
    required BuildContext context,
    required Locale locale,
    required IconData icon,
    required String titleKey,
    required String descKey,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 3,
      color: isDark ? theme.colorScheme.surfaceContainerHighest : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 32, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translations.translate(locale, titleKey),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Translations.translate(locale, descKey),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localizationProvider, child) {
        final locale = localizationProvider.locale;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        // ignore: deprecated_member_use
        return Container(
          padding: const EdgeInsets.all(24.0),
          color: isDark
              // ignore: deprecated_member_use
              ? theme.colorScheme.surfaceContainerHighest
              : const Color(0xFFF5F5F5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translations.translate(locale, 'getInTouch'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                Translations.translate(locale, 'haveQuestionsNeedSupport'),
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : const Color(0xFF616161),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6 - 24,
                    child: _buildContactCard(
                      context: context,
                      locale: locale,
                      icon: Icons.email,
                      titleKey: 'emailSupport',
                      subtitle: 'agribase5481@gmail.com',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildContactCard(
                      context: context,
                      locale: locale,
                      icon: Icons.phone,
                      titleKey: 'phoneSupport',
                      subtitle: '+8801551552954',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required Locale locale,
    required IconData icon,
    required String titleKey,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: isDark ? theme.colorScheme.surface : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              Translations.translate(locale, titleKey),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: subtitle));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$subtitle copied to clipboard'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : const Color(0xFF9E9E9E),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthPrompt(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    final localizationProvider = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );
    final locale = localizationProvider.locale;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.translate(locale, 'signOut')),
        content: Text(Translations.translate(locale, 'areYouSureSignOut')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Translations.translate(locale, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(Translations.translate(locale, 'logOut')),
                ),
              );
              await authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(Translations.translate(locale, 'signOut')),
          ),
        ],
      ),
    );
  }
}
