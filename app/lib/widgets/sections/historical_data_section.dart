import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/crops_database_service.dart';
import '../../providers/localization_provider.dart';
import '../../utils/translations.dart';
import '../../utils/translation_helper.dart';

class HistoricalDataSection extends StatefulWidget {
  const HistoricalDataSection({super.key});

  @override
  State<HistoricalDataSection> createState() => _HistoricalDataSectionState();
}

class _HistoricalDataSectionState extends State<HistoricalDataSection> {
  final CropsDatabaseService _cropsService = CropsDatabaseService();

  List<String> _crops = [];
  List<String> _years = [];
  String? _selectedCrop;
  String? _selectedYear;
  int _topCount = 10;

  List<Map<String, dynamic>> _topDistricts = [];
  Map<String, dynamic> _totalYield = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final crops = await _cropsService.getAllCrops();
      if (crops.isNotEmpty) {
        setState(() {
          _crops = crops;
          _selectedCrop = crops.first;
        });
        await _loadYearsForCrop(crops.first);
      }
    } catch (e) {
      // ignore: empty_catches
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadYearsForCrop(String crop) async {
    if (crop.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final years = await _cropsService.getYearsForCrop(crop);
      if (years.isNotEmpty) {
        setState(() {
          _years = years;
          _selectedYear = years.first;
        });
        await _loadData();
      }
    } catch (e) {
      // ignore: empty_catches
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    if (_selectedCrop == null || _selectedYear == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final limit = _topCount == -1 ? 0 : _topCount;
      final topDistricts = await _cropsService.getTopYieldDistricts(
        _selectedCrop!,
        _selectedYear!,
        limit: limit,
      );
      final totalYield = await _cropsService.getTotalYield(
        _selectedCrop!,
        _selectedYear!,
      );

      setState(() {
        _topDistricts = topDistricts;
        _totalYield = totalYield;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localizationProvider, child) {
        final locale = localizationProvider.locale;
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop Selector
            Text(
              Translations.translate(locale, 'selectCrop'),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final choice = await showDialog<String?>(
                  context: context,
                  builder: (ctx) {
                    List<String> results = List.from(_crops);
                    return StatefulBuilder(
                      builder: (c, setInner) {
                        return AlertDialog(
                          title: Text(
                            Translations.translate(locale, 'selectCrop'),
                          ),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search),
                                    hintText: locale.languageCode == 'bn'
                                        ? 'ফসল খুঁজুন'
                                        : 'Search crop',
                                  ),
                                  onChanged: (q) {
                                    setInner(() {
                                      if (q.isEmpty) {
                                        results = _crops;
                                      } else {
                                        final isBangla =
                                            q.isNotEmpty &&
                                            q.codeUnitAt(0) > 127;
                                        results = _crops.where((c) {
                                          if (isBangla) {
                                            return c.toLowerCase().contains(
                                              q.toLowerCase(),
                                            );
                                          } else {
                                            return c.toLowerCase().startsWith(
                                              q.toLowerCase(),
                                            );
                                          }
                                        }).toList();
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: results.isEmpty
                                      ? const Center(child: Text('No results'))
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: results.length,
                                          itemBuilder: (context, index) {
                                            final crop = results[index];
                                            final translated =
                                                TranslationHelper.formatCropName(
                                                  crop,
                                                  locale,
                                                );
                                            return ListTile(
                                              title: Text(translated),
                                              onTap: () =>
                                                  Navigator.of(ctx).pop(crop),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(null),
                              child: const Text('Cancel'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );

                if (choice != null) {
                  setState(() {
                    _selectedCrop = choice;
                    _selectedYear = null;
                    _years = [];
                  });
                  await _loadYearsForCrop(choice);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCrop == null
                            ? Translations.translate(locale, 'selectCrop')
                            : TranslationHelper.formatCropName(
                                _selectedCrop!,
                                locale,
                              ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Top count selector
            Row(
              children: [
                Text(locale.languageCode == 'bn' ? 'শীর্ষ দেখান:' : 'Show:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _topCount,
                  items: const [5, 10, 20, -1].map((n) {
                    final label = n == -1 ? 'All' : n.toString();
                    return DropdownMenuItem(value: n, child: Text(label));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _topCount = v);
                      _loadData();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Year Selector
            Text(
              Translations.translate(locale, 'selectYear'),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedYear,
              isExpanded: true,
              underline: Container(height: 2, color: theme.colorScheme.primary),
              items: _years.map((year) {
                final displayYear = locale.languageCode == 'bn'
                    ? TranslationHelper.formatNumber(
                        year,
                        useBengaliNumerals: true,
                      )
                    : year;
                return DropdownMenuItem(value: year, child: Text(displayYear));
              }).toList(),
              onChanged: (year) {
                if (year != null) {
                  setState(() {
                    _selectedYear = year;
                  });
                  _loadData();
                }
              },
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_selectedCrop != null && _selectedYear != null) ...[
              // Total Yield Card
              InkWell(
                onTap: () {},
                highlightColor: Colors.white.withValues(alpha: 0.1),
                splashColor: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tooltip(
                          message:
                              'Total production for the selected crop and year',
                          child: Text(
                            '${Translations.translate(locale, 'production')} ($_selectedYear)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Tooltip(
                          message: 'Total production in metric tons',
                          child: Text(
                            '${TranslationHelper.formatNumberWithCommas((_totalYield['total_production'] as num? ?? 0).toDouble(), decimalPlaces: 3, locale: locale)} ${Translations.translate(locale, 'mt')}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.agriculture,
                              color: theme.colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Average yield per hectare',
                              child: Text(
                                '${Translations.translate(locale, 'yield')}: ${TranslationHelper.formatNumberWithCommas((_totalYield['average_yield'] as num? ?? 0).toDouble(), decimalPlaces: 3, locale: locale)} ${Translations.translate(locale, 'mtPerHectare')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Top Yield Districts
              Text(
                locale.languageCode == 'bn'
                    ? 'শীর্ষ ফলন জেলা'
                    : 'Top Yield Districts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {},
                highlightColor: Colors.white.withValues(alpha: 0.1),
                splashColor: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  Translations.translate(locale, 'district'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${Translations.translate(locale, 'yield')} (MT/Ha)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${Translations.translate(locale, 'production')} (MT)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Table Rows
                        if (_topDistricts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              Translations.translate(locale, 'noData'),
                            ),
                          )
                        else
                          ...((_topCount == -1
                                  ? _topDistricts
                                  : _topDistricts.take(_topCount).toList())
                              .map((district) {
                                final yieldValue =
                                    (district['yield_per_hectare'] as num? ?? 0)
                                        .toDouble();
                                final production =
                                    (district['production_mt'] as num? ?? 0)
                                        .toDouble();
                                final districtName =
                                    district['district'] as String? ?? '';
                                final translatedDistrict =
                                    TranslationHelper.formatDistrictName(
                                      districtName,
                                      locale,
                                    );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Tooltip(
                                          message: 'District name',
                                          child: Text(
                                            translatedDistrict,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Tooltip(
                                          message: 'Yield per hectare',
                                          child: Text(
                                            TranslationHelper.formatNumberWithCommas(
                                              yieldValue,
                                              decimalPlaces: 3,
                                              locale: locale,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Tooltip(
                                          message: 'Total production',
                                          child: Text(
                                            TranslationHelper.formatNumberWithCommas(
                                              production,
                                              decimalPlaces: 3,
                                              locale: locale,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })
                              .toList()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
