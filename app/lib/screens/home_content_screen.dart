import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'calculator_screen.dart';
import 'my_crops_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/soil_provider.dart';
import '../providers/location_provider.dart';
import '../providers/my_crops_provider.dart';
import '../services/crop_info_service.dart';
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

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

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
      final myCropsProvider = Provider.of<MyCropsProvider>(
        context,
        listen: false,
      );

      // Initialize my crops from storage
      await myCropsProvider.initialize();

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
        final locProvider = Provider.of<LocalizationProvider>(
          context,
          listen: false,
        );
        final locationName =
            locationProvider.districtName ??
            (locProvider.locale.languageCode == 'bn' ? 'অবস্থান' : 'Location');

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
            'titleBn': 'উচ্চ বৃষ্টিপাত প্রত্যাশিত',
            'message':
                '${today.precipitationProbability}% chance of rain today. Delay spraying operations.',
            'messageBn':
                '${today.precipitationProbability}% আজ বৃষ্টির সম্ভাবনা। স্প্রে করা থেকে বিরত থাকুন।',
            'severity': 'warning',
          });
        }

        // Temperature-based insight
        if (today.maxTemp > 32) {
          insights.add({
            'icon': Icons.wb_sunny,
            'color': Colors.orange,
            'title': 'Heat Alert',
            'titleBn': 'তাপ সতর্কতা',
            'message':
                'High temperature (${today.maxTemp.toStringAsFixed(1)}°C). Ensure adequate irrigation.',
            'messageBn':
                'উচ্চ তাপমাত্রা (${today.maxTemp.toStringAsFixed(1)}°C)। পর্যাপ্ত সেচ নিশ্চিত করুন।',
            'severity': 'warning',
          });
        } else if (today.maxTemp > 25 && today.maxTemp < 30) {
          insights.add({
            'icon': Icons.wb_sunny,
            'color': Colors.green,
            'title': 'Optimal Growing Conditions',
            'titleBn': 'সর্বোত্তম বৃদ্ধির অবস্থা',
            'message':
                'Temperature range ideal for most crops. Good time for field activities.',
            'messageBn':
                'বেশিরভাগ ফসলের জন্য আদর্শ তাপমাত্রা পরিসীমা। মাঠের কার্যক্রমের জন্য ভালো সময়।',
            'severity': 'tip',
          });
        }

        // Wind speed alert
        if (today.windSpeed > 15) {
          insights.add({
            'icon': Icons.air,
            'color': Colors.orange,
            'title': 'High Wind Alert',
            'titleBn': 'উচ্চ বাতাস সতর্কতা',
            'message':
                'Wind speed ${today.windSpeed.toStringAsFixed(1)} km/h. Avoid pesticide spraying.',
            'messageBn':
                'বাতাসের গতি ${today.windSpeed.toStringAsFixed(1)} কিমি/ঘণ্টা। কীটনাশক স্প্রে করা এড়িয়ে চলুন।',
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
            'titleBn': 'অম্লীয় মাটি শনাক্ত হয়েছে',
            'message':
                'pH ${soil.ph.toStringAsFixed(1)} - Consider lime application to raise pH.',
            'messageBn':
                'pH ${soil.ph.toStringAsFixed(1)} - pH বাড়াতে চুন প্রয়োগ বিবেচনা করুন।',
            'severity': 'warning',
          });
        } else if (soil.ph > 7.8) {
          insights.add({
            'icon': Icons.eco,
            'color': Colors.amber,
            'title': 'Alkaline Soil',
            'titleBn': 'ক্ষারীয় মাটি',
            'message':
                'pH ${soil.ph.toStringAsFixed(1)} - Sulfur addition may help lower pH.',
            'messageBn':
                'pH ${soil.ph.toStringAsFixed(1)} - pH কমাতে সালফার সংযোজন সাহায্য করতে পারে।',
            'severity': 'warning',
          });
        } else {
          insights.add({
            'icon': Icons.eco,
            'color': Colors.green,
            'title': 'Optimal Soil pH',
            'titleBn': 'সর্বোত্তম মাটির pH',
            'message':
                'pH ${soil.ph.toStringAsFixed(1)} - Ideal range for most crops.',
            'messageBn':
                'pH ${soil.ph.toStringAsFixed(1)} - বেশিরভাগ ফসলের জন্য আদর্শ পরিসীমা।',
            'severity': 'tip',
          });
        }

        if (soil.organicCarbon < 1.0) {
          insights.add({
            'icon': Icons.compost,
            'color': Colors.brown,
            'title': 'Low Organic Matter',
            'titleBn': 'কম জৈব পদার্থ',
            'message':
                'Consider adding compost to improve soil fertility and water retention.',
            'messageBn':
                'মাটির উর্বরতা এবং জল ধারণ ক্ষমতা উন্নত করতে কম্পোস্ট যোগ করুন।',
            'severity': 'tip',
          });
        }
      }

      // Crop-based insights from My Crops
      final myCropsProvider = Provider.of<MyCropsProvider>(
        context,
        listen: false,
      );

      if (myCropsProvider.crops.isNotEmpty) {
        // Check for crops ready for harvest
        final readyForHarvest = myCropsProvider.cropsReadyForHarvest;
        if (readyForHarvest.isNotEmpty) {
          final cropName = readyForHarvest.first.cropName;
          final cropNameBn = readyForHarvest.first.cropNameBn;
          insights.insert(0, {
            'icon': Icons.agriculture,
            'color': Colors.green,
            'title': '${_capitalizeFirstLetter(cropName)} Ready for Harvest',
            'titleBn': '$cropNameBn কাটার জন্য প্রস্তুত',
            'message':
                'Your ${_capitalizeFirstLetter(cropName)} crop has reached maturity. Check the field for harvest readiness.',
            'messageBn':
                'আপনার $cropNameBn পরিপক্ব হয়েছে। কাটার জন্য মাঠ পরীক্ষা করুন।',
            'severity': 'tip',
          });
        }

        // Check for crops needing attention (0-7 days to harvest)
        final needsAttention = myCropsProvider.cropsNeedingAttention;
        for (final crop in needsAttention) {
          final daysLeft = crop.daysUntilHarvest;
          if (daysLeft > 0 && daysLeft <= 7) {
            insights.add({
              'icon': Icons.schedule,
              'color': Colors.orange,
              'title':
                  '${_capitalizeFirstLetter(crop.cropName)} Approaching Harvest',
              'titleBn': '${crop.cropNameBn} কাটা নিকটবর্তী',
              'message':
                  'Your ${_capitalizeFirstLetter(crop.cropName)} will be ready in $daysLeft days. Start preparing for harvest.',
              'messageBn':
                  'আপনার ${crop.cropNameBn} $daysLeft দিনের মধ্যে প্রস্তুত হবে। কাটার প্রস্তুতি শুরু করুন।',
              'severity': 'warning',
            });
            break; // Only show one approaching harvest notification
          }
        }

        // Add crop-specific weather warnings
        if (weather != null && weather.dailyForecasts.isNotEmpty) {
          final cropService = CropInfoService();
          for (final crop in myCropsProvider.crops) {
            final cropInfo = cropService.getCropInfo(crop.cropName);
            if (cropInfo != null) {
              final daysSincePlanting = DateTime.now()
                  .difference(crop.plantedDate)
                  .inDays;
              final currentTemp =
                  weather.currentTemp ?? weather.dailyForecasts.first.maxTemp;
              final precipitation = weather
                  .dailyForecasts
                  .first
                  .precipitationProbability
                  .toDouble();

              final warningMaps = cropService.getWeatherBasedWarnings(
                crop.cropName,
                daysSincePlanting,
                currentTemp: currentTemp,
                precipitation: precipitation,
              );

              for (final warning in warningMaps) {
                insights.add({
                  'icon': Icons.warning_amber,
                  'color': Colors.red,
                  'title': '${_capitalizeFirstLetter(crop.cropName)} Alert',
                  'titleBn': '${crop.cropNameBn} সতর্কতা',
                  'message': warning['message'],
                  'messageBn': warning['messageBn'] ?? warning['message'],
                  'severity': 'warning',
                });
              }
            }
          }
        }
      }

      // Default insight if no data available
      if (insights.isEmpty) {
        insights.add({
          'icon': Icons.tips_and_updates,
          'color': Colors.blue,
          'title': 'Welcome to AgriBase',
          'titleBn': 'এগ্রিবেসে স্বাগতম',
          'message':
              'Enable location access to get personalized farming insights.',
          'messageBn':
              'ব্যক্তিগতকৃত কৃষি অন্তর্দৃষ্টি পেতে অবস্থান অ্যাক্সেস সক্ষম করুন।',
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
              'titleBn': 'ডেটা লোড করতে ত্রুটি',
              'message':
                  'Failed to load insights. Please check your location and try again.',
              'messageBn':
                  'অন্তর্দৃষ্টি লোড করতে ব্যর্থ হয়েছে। আপনার অবস্থান পরীক্ষা করুন এবং পুনরায় চেষ্টা করুন।',
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Section with greeting
                    _buildHeroSection(
                      context,
                      isAuthenticated,
                      locale,
                      authProvider,
                    ),

                    // Daily Insight Widget (AI-powered tip) - Only for authenticated users
                    if (isAuthenticated)
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

                    // My Crops Section (only for authenticated users)
                    if (isAuthenticated)
                      _buildMyCropsSection(context, isBangla),

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
    // make the container expanded, as it is being fixed width somehow
    return Container(
      width: double.infinity,
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
                            color: isDark
                                ? const Color.fromARGB(255, 65, 78, 219)
                                : const Color(0xFF1A237E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBangla ? 'দৈনিক ইনসাইট' : 'Daily Insight',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color.fromARGB(255, 65, 78, 219)
                                  : const Color(0xFF1A237E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isBangla
                            ? (insight['titleBn'] as String? ??
                                  insight['title'] as String)
                            : insight['title'] as String,
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
              isBangla
                  ? (insight['messageBn'] as String? ??
                        insight['message'] as String)
                  : insight['message'] as String,
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                if (weather != null && weather.dailyForecasts.isNotEmpty)
                  _buildStatusChip(
                    context,
                    Icons.cloud,
                    isBangla ? 'আবহাওয়া' : 'Weather',
                    weather.dailyForecasts.first.getWeatherDescription(),
                    _getWeatherColor(weather.dailyForecasts.first.weatherCode),
                  ),
                if (soil != null)
                  _buildStatusChip(
                    context,
                    Icons.water,
                    isBangla ? 'মাটির ধরণ' : 'Soil Type',
                    soil.soilType,
                    Colors.green,
                  ),
                if (weather != null && weather.dailyForecasts.isNotEmpty)
                  _buildStatusChip(
                    context,
                    Icons.bug_report,
                    isBangla ? 'কীট ঝুঁকি' : 'Pest Risk',
                    _getPestRisk(weather.dailyForecasts.first, isBangla),
                    _getPestRiskColor(weather.dailyForecasts.first),
                  ),
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
    final isDark = theme.brightness == Brightness.dark;

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
                isDark
                    ? const Color.fromARGB(255, 65, 78, 219)
                    : const Color(0xFF1A237E),
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

  Widget _buildMyCropsSection(BuildContext context, bool isBangla) {
    return Consumer<MyCropsProvider>(
      builder: (context, myCropsProvider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final crops = myCropsProvider.crops;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.grass,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isBangla ? 'আমার ফসল' : 'My Crops',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyCropsScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      crops.isEmpty ? Icons.add : Icons.arrow_forward,
                      size: 18,
                    ),
                    label: Text(
                      crops.isEmpty
                          ? (isBangla ? 'ফসল যোগ করুন' : 'Add Crops')
                          : (isBangla ? 'সব দেখুন' : 'View All'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (crops.isEmpty)
                _buildEmptyCropsCard(context, isBangla)
              else
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: crops.length > 5 ? 5 : crops.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final crop = crops[index];
                      return _buildCropPreviewCard(
                        context,
                        crop,
                        isBangla,
                        isDark,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCropsCard(BuildContext context, bool isBangla) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyCropsScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.green.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              isBangla ? 'আপনার ফসল ট্র্যাক করুন' : 'Track Your Crops',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isBangla
                  ? 'ফসল যোগ করে ব্যক্তিগত ইনসাইট পান'
                  : 'Add crops to get personalized insights',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropPreviewCard(
    BuildContext context,
    dynamic crop,
    bool isBangla,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final progress = crop.growthProgress;
    final daysLeft = crop.daysUntilHarvest;

    Color progressColor;
    if (progress >= 1.0) {
      progressColor = Colors.green;
    } else if (progress >= 0.7) {
      progressColor = Colors.orange;
    } else {
      progressColor = theme.colorScheme.primary;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyCropsScreen()),
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: progressColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: progressColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                if (progress >= 1.0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✓',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isBangla
                  ? crop.cropNameBn
                  : _capitalizeFirstLetter(crop.cropName),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              progress >= 1.0
                  ? (isBangla ? 'প্রস্তুত' : 'Ready')
                  : (isBangla ? '$daysLeft দিন বাকি' : '$daysLeft days left'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: progressColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: progressColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
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
            child: Text(
              Translations.translate(locale, 'signOut'),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
