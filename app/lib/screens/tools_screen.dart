import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/localization_provider.dart';
import 'calculator_screen.dart';
import 'crop_rotation_screen.dart';
import 'settings_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

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
                Icon(Icons.build_circle, color: theme.colorScheme.onPrimary),
                const SizedBox(width: 8),
                Text(
                  isBangla ? 'টুলস' : 'Tools',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calculators Section
                _buildSectionHeader(
                  context,
                  Icons.calculate,
                  isBangla ? 'ক্যালকুলেটর' : 'Calculators',
                  isBangla
                      ? 'কৃষি গণনা করুন'
                      : 'Agricultural calculation tools',
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    _buildWideToolCard(
                      context: context,
                      icon: Icons.science,
                      title: isBangla ? 'সার' : 'Fertilizer',
                      subtitle: isBangla ? 'ক্যালকুলেটর' : 'Calculator',
                      color: Colors.green,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const CalculatorScreen(mode: 'fertilizer'),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    _buildWideToolCard(
                      context: context,
                      icon: Icons.grain,
                      title: isBangla ? 'বীজ' : 'Seed',
                      subtitle: isBangla ? 'ক্যালকুলেটর' : 'Calculator',
                      color: Colors.amber.shade700,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const CalculatorScreen(mode: 'seed'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Planning Section
                _buildSectionHeader(
                  context,
                  Icons.event_note,
                  isBangla ? 'পরিকল্পনা' : 'Planning',
                  isBangla ? 'ফসল পরিকল্পনা টুল' : 'Crop planning tools',
                ),
                const SizedBox(height: 12),
                _buildWideToolCard(
                  context: context,
                  icon: Icons.loop,
                  title: isBangla ? 'ফসল চক্র' : 'Crop Rotation',
                  subtitle: isBangla
                      ? 'মাটির স্বাস্থ্য বজায় রাখার জন্য পরবর্তী ফসল পরিকল্পনা করুন'
                      : 'Plan next crops to maintain soil health',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CropRotationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Settings Section
                _buildSectionHeader(
                  context,
                  Icons.settings,
                  isBangla ? 'সেটিংস' : 'Settings',
                  isBangla ? 'অ্যাপ কনফিগার করুন' : 'Configure your app',
                ),
                const SizedBox(height: 12),
                _buildWideToolCard(
                  context: context,
                  icon: Icons.tune,
                  title: isBangla ? 'অ্যাপ সেটিংস' : 'App Settings',
                  subtitle: isBangla
                      ? 'থিম, ভাষা এবং ফন্ট সাইজ পরিবর্তন করুন'
                      : 'Change theme, language and font size',
                  color: Colors.blueGrey,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Quick Tips Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                        theme.colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isBangla ? 'দ্রুত টিপস' : 'Quick Tips',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTipItem(
                        context,
                        isBangla
                            ? '• BARC সুপারিশ অনুযায়ী সার ব্যবহার করুন'
                            : '• Use fertilizer based on BARC recommendations',
                      ),
                      _buildTipItem(
                        context,
                        isBangla
                            ? '• ফসল চক্র মাটির উর্বরতা বাড়ায়'
                            : '• Crop rotation improves soil fertility',
                      ),
                      _buildTipItem(
                        context,
                        isBangla
                            ? '• সঠিক বীজ হার ভালো ফলনের জন্য গুরুত্বপূর্ণ'
                            : '• Correct seed rate is crucial for good yields',
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWideToolCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
