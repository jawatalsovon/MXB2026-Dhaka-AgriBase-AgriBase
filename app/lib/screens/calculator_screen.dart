import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/localization_provider.dart';
import '../services/fertilizer_service.dart';
import '../utils/translation_helper.dart';

class CalculatorScreen extends StatefulWidget {
  final String mode; // 'fertilizer' or 'seed'
  const CalculatorScreen({super.key, this.mode = 'fertilizer'});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late FertilizerGuidanceService _fertilizerService;

  // Fertilizer Calculator State
  String selectedCrop = 'rice';
  double enteredAreaFert = 1.0;
  String selectedAreaUnitFert = 'hectare';
  double areaInHectares = 1.0;
  Map<String, dynamic>? fertilizerPlan;

  // Seed Calculator State
  double seedRatePerHectare = 40; // kg/ha for rice by default
  double enteredAreaSeed = 1.0;
  String selectedAreaUnitSeed = 'hectare';
  String selectedSeedCrop = 'rice';

  // Yield Calculator State
  // (Yield calculator removed per feature request)

  @override
  void initState() {
    super.initState();
    _fertilizerService = FertilizerGuidanceService();
    _calculateFertilizer();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _calculateFertilizer() {
    setState(() {
      fertilizerPlan = _fertilizerService.getFertilizerPlan(
        selectedCrop,
        areaInHectares,
      );
    });
  }

  double _areaInHectares(double value, String unit) {
    switch (unit) {
      case 'hectare':
        return value;
      case 'bigha': // 1 bigha ≈ 0.66 hectares (Bangladesh)
        return value * 0.66;
      case 'acre': // 1 acre ≈ 0.405 hectares
        return value * 0.405;
      case 'decimal': // 1 decimal ≈ 0.004 hectares
        return value * 0.004;
      default:
        return value;
    }
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
            title: Text(''),
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(theme, isBangla),
                const SizedBox(height: 16),
                if (widget.mode == 'seed')
                  _buildSeedCalculator(theme, isBangla)
                else
                  _buildFertilizerCalculator(theme, isBangla),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFertilizerCalculator(ThemeData theme, bool isBangla) {
    final locale = Provider.of<LocalizationProvider>(context).locale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBanner(
          theme,
          isBangla
              ? 'সার ক্যালকুলেটর উন্নয়নাধীন। ফলাফল শুধুমাত্র রেফারেন্সের জন্য।'
              : 'Fertilizer calculator is under development. Results are for reference only.',
        ),
        const SizedBox(height: 12),
        _buildInfoPill(
          theme,
          isBangla
              ? 'BARC সুপারিশের উপর ভিত্তি করে'
              : 'Based on BARC recommendations',
        ),
        const SizedBox(height: 16),
        _buildCard(
          theme,
          title: isBangla ? 'ইনপুট' : 'Inputs',
          children: [
            Text(
              isBangla ? 'ফসল নির্বাচন করুন' : 'Select crop',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCrop,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              isExpanded: true,
              items: _fertilizerService
                  .getAvailableCrops()
                  .map(
                    (crop) => DropdownMenuItem(
                      value: crop,
                      child: Text(
                        TranslationHelper.formatCropName(crop, locale),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCrop = value;
                    _calculateFertilizer();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              isBangla ? 'খামারের আয়তন' : 'Farm area',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: '1.0',
                labelText: isBangla ? 'এলাকা' : 'Area',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final parsed = double.tryParse(value);
                setState(() {
                  enteredAreaFert = parsed ?? enteredAreaFert;
                  areaInHectares = _areaInHectares(
                    enteredAreaFert,
                    selectedAreaUnitFert,
                  );
                  _calculateFertilizer();
                });
              },
            ),
            const SizedBox(height: 12),
            _buildUnitChips(
              theme,
              selected: selectedAreaUnitFert,
              onSelect: (unit) {
                setState(() {
                  selectedAreaUnitFert = unit;
                  areaInHectares = _areaInHectares(
                    enteredAreaFert,
                    selectedAreaUnitFert,
                  );
                  _calculateFertilizer();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (fertilizerPlan != null)
          _buildCard(
            theme,
            title: isBangla ? 'সারের প্রয়োজনীয়তা' : 'Fertilizer requirements',
            children: [
              _buildFertilizerCard(
                theme,
                isBangla ? 'নাইট্রোজেন (N)' : 'Nitrogen (N)',
                '${fertilizerPlan!['npkValues']['nitrogen']} kg',
                isBangla
                    ? 'ইউরিয়া (46% N): ${fertilizerPlan!['commonFertilizers']['urea']} kg'
                    : 'Urea (46% N): ${fertilizerPlan!['commonFertilizers']['urea']} kg',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildFertilizerCard(
                theme,
                isBangla ? 'ফসফরাস (P)' : 'Phosphorus (P)',
                '${fertilizerPlan!['npkValues']['phosphorus']} kg',
                isBangla
                    ? 'টিএসপি (46% P₂O₅): ${fertilizerPlan!['commonFertilizers']['tsp']} kg'
                    : 'TSP (46% P₂O₅): ${fertilizerPlan!['commonFertilizers']['tsp']} kg',
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildFertilizerCard(
                theme,
                isBangla ? 'পটাসিয়াম (K)' : 'Potassium (K)',
                '${fertilizerPlan!['npkValues']['potassium']} kg',
                isBangla
                    ? 'এমওপি (60% K₂O): ${fertilizerPlan!['commonFertilizers']['mop']} kg'
                    : 'MOP (60% K₂O): ${fertilizerPlan!['commonFertilizers']['mop']} kg',
                Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                theme,
                title: isBangla ? '🌱 জৈব' : '🌱 Organic',
                body: fertilizerPlan!['organicRecommendation'],
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                theme,
                title: isBangla ? '📝 প্রয়োগের টিপস' : '📝 Application Tips',
                body: fertilizerPlan!['notes'],
                color: Colors.amber,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFertilizerCard(
    ThemeData theme,
    String title,
    String amount,
    String commercial,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                amount,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            commercial,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedCalculator(ThemeData theme, bool isBangla) {
    final locale = Provider.of<LocalizationProvider>(context).locale;

    final seedRateCrops = {
      'rice': 40,
      'wheat': 125,
      'corn': 20,
      'lentil': 50,
      'chickpea': 90,
    };

    final totalSeedKg =
        seedRatePerHectare *
        _areaInHectares(enteredAreaSeed, selectedAreaUnitSeed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBanner(
          theme,
          isBangla
              ? 'বীজ ক্যালকুলেটর উন্নয়নাধীন। ফলাফল শুধুমাত্র রেফারেন্সের জন্য।'
              : 'Seed calculator is under development. Results are for reference only.',
        ),
        const SizedBox(height: 12),
        _buildInfoPill(
          theme,
          isBangla
              ? 'BARC সুপারিশের উপর ভিত্তি করে'
              : 'Based on BARC recommendations',
        ),
        const SizedBox(height: 16),
        _buildCard(
          theme,
          title: isBangla ? 'ইনপুট' : 'Inputs',
          children: [
            Text(
              isBangla ? 'ফসল নির্বাচন করুন' : 'Select crop',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedSeedCrop,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: seedRateCrops.keys
                  .map(
                    (crop) => DropdownMenuItem(
                      value: crop,
                      child: Text(
                        TranslationHelper.formatCropName(crop, locale),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedSeedCrop = value;
                    seedRatePerHectare = seedRateCrops[value]?.toDouble() ?? 40;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              isBangla ? 'খামারের আয়তন' : 'Farm area',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: isBangla ? 'এলাকা প্রবেশ করুন' : 'Enter area',
                labelText: isBangla ? 'এলাকা' : 'Area',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final parsed = double.tryParse(value);
                setState(() {
                  enteredAreaSeed = parsed ?? enteredAreaSeed;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildUnitChips(
              theme,
              selected: selectedAreaUnitSeed,
              onSelect: (unit) {
                setState(() {
                  selectedAreaUnitSeed = unit;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          theme,
          title: isBangla ? 'বীজের প্রয়োজন' : 'Seed requirement',
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBangla ? 'মোট বীজের প্রয়োজন' : 'Total seed needed',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${totalSeedKg.toStringAsFixed(2)} kg',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.green[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHero(ThemeData theme, bool isBangla) {
    final isSeed = widget.mode == 'seed';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSeed
                ? (isBangla ? 'বীজ ক্যালকুলেটর' : 'Seed Calculator')
                : (isBangla ? 'সার ক্যালকুলেটর' : 'Fertilizer Calculator'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isBangla
                ? 'আপনার খামারের জন্য দ্রুত গাইড'
                : 'Fast guidance for your field',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.orange[900], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!),
      ),
      width: double.infinity,
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(color: Colors.blue[900]),
      ),
    );
  }

  Widget _buildCard(
    ThemeData theme, {
    required String title,
    required List<Widget> children,
  }) {
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildUnitChips(
    ThemeData theme, {
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    const units = [
      {'value': 'hectare', 'label': 'ha'},
      {'value': 'bigha', 'label': 'bigha'},
      {'value': 'acre', 'label': 'acre'},
      {'value': 'decimal', 'label': 'decimal'},
    ];

    return Wrap(
      spacing: 8,
      children: units
          .map(
            (u) => ChoiceChip(
              label: Text(u['label']!),
              selected: selected == u['value'],
              onSelected: (_) => onSelect(u['value']!),
              selectedColor: theme.colorScheme.primary.withOpacity(0.15),
              labelStyle: TextStyle(
                color: selected == u['value']
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInfoCard(
    ThemeData theme, {
    required String title,
    required String body,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
