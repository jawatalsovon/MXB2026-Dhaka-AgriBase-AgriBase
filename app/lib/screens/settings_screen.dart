import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Assuming providers are set up
import '../providers/theme_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/font_size_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/translations.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;
    final theme = Theme.of(context);
    final locale = localizationProvider.locale;

    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.translate(locale, 'settings')),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(theme, Translations.translate(locale, 'appearance'), [
              _buildSwitchRow(
                theme,
                icon: Icons.brightness_6,
                label: Translations.translate(locale, 'darkMode'),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
              const SizedBox(height: 12),
              _buildLanguageRow(theme, locale, localizationProvider),
            ]),
            const SizedBox(height: 16),
            _buildCard(theme, Translations.translate(locale, 'fontSize'), [
              Consumer<FontSizeProvider>(
                builder: (context, fontSizeProvider, _) {
                  return Row(
                    spacing: 12,
                    // runSpacing: 8,
                    children: [
                      _buildChipButton(
                        theme,
                        label: Translations.translate(locale, 'small'),
                        selected: fontSizeProvider.fontSize == 12.0,
                        onTap: () => fontSizeProvider.setFontSize(12.0),
                      ),
                      _buildChipButton(
                        theme,
                        label: Translations.translate(locale, 'default'),
                        selected: fontSizeProvider.fontSize == 14.0,
                        onTap: () => fontSizeProvider.setFontSize(14.0),
                      ),
                      _buildChipButton(
                        theme,
                        label: Translations.translate(locale, 'large'),
                        selected: fontSizeProvider.fontSize == 16.0,
                        onTap: () => fontSizeProvider.setFontSize(16.0),
                      ),
                    ],
                  );
                },
              ),
            ]),
            const SizedBox(height: 16),
            _buildCard(theme, Translations.translate(locale, 'general'), [
              _buildActionRow(
                theme,
                icon: Icons.privacy_tip,
                label: Translations.translate(locale, 'privacyPolicy'),
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildActionRow(
                theme,
                icon: Icons.info_outline,
                label: Translations.translate(locale, 'aboutUs'),
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 16),
            _buildCard(theme, Translations.translate(locale, 'account'), [
              if (!isAuthenticated)
                _buildActionRow(
                  theme,
                  icon: Icons.login,
                  label: Translations.translate(locale, 'login'),
                  color: theme.colorScheme.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(
                          onGuestMode: () => Navigator.of(context).pop(),
                        ),
                      ),
                    );
                  },
                ),
              if (isAuthenticated)
                _buildActionRow(
                  theme,
                  icon: Icons.logout,
                  label: Translations.translate(locale, 'logOut'),
                  color: theme.colorScheme.error,
                  onTap: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ThemeData theme, String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        _buildIconBadge(theme, icon),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildLanguageRow(
    ThemeData theme,
    Locale locale,
    LocalizationProvider localizationProvider,
  ) {
    return Row(
      children: [
        _buildIconBadge(theme, Icons.language),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            Translations.translate(locale, 'language'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: locale.languageCode == 'bn' ? 'bangla' : 'english',
            items: [
              DropdownMenuItem(
                value: 'english',
                child: Text(Translations.translate(locale, 'english')),
              ),
              DropdownMenuItem(
                value: 'bangla',
                child: Text(Translations.translate(locale, 'bangla')),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                localizationProvider.setLanguage(
                  value == 'bangla' ? 'Bangla' : 'English',
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChipButton(
    ThemeData theme, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildActionRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final resolvedColor = color ?? theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _buildIconBadge(theme, icon, color: resolvedColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBadge(ThemeData theme, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: color ?? theme.colorScheme.primary),
    );
  }
}
