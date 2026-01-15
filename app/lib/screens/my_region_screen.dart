import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/crops_database_service.dart';
import '../services/database_service.dart';
import '../utils/data_utils.dart';
import '../providers/localization_provider.dart';
import '../utils/translations.dart';
import '../utils/translation_helper.dart';

class MyRegionScreen extends StatefulWidget {
  final bool embedded;
  const MyRegionScreen({super.key, this.embedded = false});

  @override
  State<MyRegionScreen> createState() => _MyRegionScreenState();
}

class _MyRegionScreenState extends State<MyRegionScreen> {
  final CropsDatabaseService _cropsService = CropsDatabaseService();

  List<String> _districts = [];
  List<String> _displayDistricts = [];
  List<String> _years = [];
  String? _selectedDistrict;
  String? _selectedDisplayDistrict;
  String? _selectedYear;

  List<Map<String, dynamic>> _topCrops = [];
  bool _isLoading = false;
  int _topCount = 10;

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
      final districts = await _cropsService.getAllDistricts();
      final displayDistricts = districts.map(cleanDistrict).toSet().toList()
        ..sort();
      if (districts.isNotEmpty) {
        setState(() {
          _districts = districts;
          _displayDistricts = displayDistricts;
          _selectedDistrict = districts.firstWhere(
            (d) => cleanDistrict(d) == displayDistricts.first,
          );
          _selectedDisplayDistrict = displayDistricts.first;
        });
        await _loadYearsForDistrict(_selectedDistrict!);
      }
    } catch (e) {
      // ignore: empty_catches
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadYearsForDistrict(String district) async {
    if (district.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get years from the service (supports both web and native)
      final years = await _cropsService.getYearsForDistrict(district);

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
    if (_selectedDistrict == null || _selectedYear == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final limit = _topCount == -1 ? 0 : _topCount;
      final topCrops = await _cropsService.getTopCropsForDistrict(
        _selectedDistrict!,
        _selectedYear!,
        limit: limit,
      );
      setState(() {
        _topCrops = topCrops;
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
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final locale = localizationProvider.locale;
    final theme = Theme.of(context);

    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // District Selector
          Text(
            Translations.translate(locale, 'selectDistrict'),
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
                  List<String> results = List.from(_displayDistricts);
                  return StatefulBuilder(
                    builder: (c, setInner) {
                      return AlertDialog(
                        title: Text(
                          Translations.translate(locale, 'selectDistrict'),
                        ),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search),
                                  hintText: 'Search district',
                                ),
                                onChanged: (q) {
                                  setInner(() {
                                    results = _displayDistricts
                                        .where(
                                          (d) => d.toLowerCase().contains(
                                            q.toLowerCase(),
                                          ),
                                        )
                                        .toList();
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
                                          final district = results[index];
                                          final translated =
                                              TranslationHelper.formatDistrictName(
                                                district,
                                                locale,
                                              );
                                          return ListTile(
                                            title: Text(translated),
                                            onTap: () =>
                                                Navigator.of(ctx).pop(district),
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
                  _selectedDisplayDistrict = choice;
                  _selectedDistrict = _districts.firstWhere(
                    (d) => cleanDistrict(d) == choice,
                  );
                  _selectedYear = null;
                  _years = [];
                });
                await _loadYearsForDistrict(_selectedDistrict!);
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
                      _selectedDisplayDistrict ??
                          Translations.translate(locale, 'selectDistrict'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
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
              final displayYear = TranslationHelper.formatNumber(
                year,
                useBengaliNumerals: locale.languageCode == 'bn',
              );
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Show:'),
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
          const SizedBox(height: 12),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_topCrops.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(Translations.translate(locale, 'noData')),
              ),
            )
          else ...[
            Text(
              'Top ${_topCount == -1 ? 'All' : _topCount.toString()} Most Yielding Crops in $_selectedDistrict ($_selectedYear)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Rank',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              Translations.translate(locale, 'crop'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${Translations.translate(locale, 'production')} (MT)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${Translations.translate(locale, 'yield')} (MT/Ha)',
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
                    ...((_topCount == -1
                            ? _topCrops
                            : _topCrops.take(_topCount).toList())
                        .asMap()
                        .entries
                        .map((entry) {
                          final index = entry.key;
                          final crop = entry.value;
                          final production =
                              (crop['production_mt'] as num? ?? 0).toDouble();
                          final yieldValue =
                              (crop['yield_per_hectare'] as num? ?? 0)
                                  .toDouble();
                          final cropName = crop['crop_name'] as String? ?? '';
                          final translatedCrop =
                              TranslationHelper.formatCropName(
                                cropName,
                                locale,
                              );

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    // decoration: BoxDecoration(
                                    //   color: index < 3
                                    //       ? Colors.amber.withValues(alpha: 0.2)
                                    //       : Colors.grey.withValues(alpha: 0.1),
                                    //   borderRadius: BorderRadius.circular(8),
                                    // ),
                                    child: Text(
                                      TranslationHelper.formatNumber(
                                        (index + 1).toString(),
                                        useBengaliNumerals:
                                            locale.languageCode == 'bn',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: index < 3
                                            ? Colors.amber[900]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    translatedCrop,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    TranslationHelper.formatNumberWithCommas(
                                      production,
                                      decimalPlaces: 3,
                                      locale: locale,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    TranslationHelper.formatNumberWithCommas(
                                      yieldValue,
                                      decimalPlaces: 3,
                                      locale: locale,
                                    ),
                                    textAlign: TextAlign.right,
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
          ],
        ],
      ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        title: Text(
          Translations.translate(locale, 'myRegion'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: body,
    );
  }
}
