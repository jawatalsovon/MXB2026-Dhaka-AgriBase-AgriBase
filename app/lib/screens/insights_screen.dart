import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/localization_provider.dart';
import 'analytics_screen.dart';
import 'discover_screen.dart';
import 'my_region_screen.dart';
import '../widgets/sections/historical_data_section.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LocalizationProvider>(
      builder: (context, localizationProvider, child) {
        final locale = localizationProvider.locale;
        final isBangla = locale.languageCode == 'bn';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights, color: theme.colorScheme.onPrimary),
                const SizedBox(width: 8),
                Text(
                  isBangla ? 'ইনসাইটস' : 'Insights',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              //isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: [
                Tab(
                  icon: const Icon(Icons.history, size: 20),
                  text: isBangla ? 'ঐতিহাসিক' : 'Historical',
                ),
                Tab(
                  icon: const Icon(Icons.pie_chart, size: 20),
                  text: isBangla ? 'বিশ্লেষণ' : 'Analytics',
                ),
                Tab(
                  icon: const Icon(Icons.map, size: 20),
                  text: isBangla ? 'মানচিত্র' : 'Map',
                ),
                Tab(
                  icon: const Icon(Icons.location_on, size: 20),
                  text: isBangla ? 'আমার এলাকা' : 'My Region',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Historical Data Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      context,
                      Icons.history,
                      isBangla ? 'ঐতিহাসিক ডেটা' : 'Historical Data',
                      isBangla
                          ? 'বিগত বছরের ফসল উৎপাদন পরিসংখ্যান'
                          : 'Past years crop production statistics',
                    ),
                    const SizedBox(height: 16),
                    const HistoricalDataSection(),
                  ],
                ),
              ),
              // Analytics Tab (Pie Charts)
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      context,
                      Icons.pie_chart,
                      isBangla ? 'বিশ্লেষণ' : 'Analytics',
                      isBangla
                          ? 'ফসল উৎপাদনের বিশ্লেষণাত্মক তথ্য'
                          : 'Analytical data of crop production',
                    ),
                    const SizedBox(height: 16),
                    const AnalyticsContent(),
                  ],
                ),
              ),

              // Map/Discover Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      context,
                      Icons.map,
                      isBangla ? 'মানচিত্র' : 'Map',
                      isBangla
                          ? 'ফসল উৎপাদনের মানচিত্রভিত্তিক তথ্য'
                          : 'Map-based data of crop production',
                    ),
                    const SizedBox(height: 16),
                    const DiscoverContent(),
                  ],
                ),
              ),

              // My Region Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      context,
                      Icons.location_on,
                      isBangla ? 'আমার এলাকা' : 'My Region',
                      isBangla
                          ? 'আমার এলাকার ফসল উৎপাদন তথ্য'
                          : 'Crop production data of my region',
                    ),
                    const SizedBox(height: 16),
                    const MyRegionContent(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

// Extracted content from AnalyticsScreen for embedding
class AnalyticsContent extends StatelessWidget {
  const AnalyticsContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Re-use the body content from AnalyticsScreen
    return const AnalyticsScreen(embedded: true);
  }
}

// Extracted content from DiscoverScreen for embedding
class DiscoverContent extends StatelessWidget {
  const DiscoverContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const DiscoverScreen(embedded: true);
  }
}

// Extracted content from MyRegionScreen for embedding
class MyRegionContent extends StatelessWidget {
  const MyRegionContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyRegionScreen(embedded: true);
  }
}
