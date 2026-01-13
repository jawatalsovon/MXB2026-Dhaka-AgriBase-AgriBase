import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/crops_database_service.dart';
import '../models/district_data.dart';
import '../widgets/interactive_bangladesh_map.dart';
import '../providers/localization_provider.dart';
import '../utils/translations.dart';
import '../utils/translation_helper.dart';

class DiscoverScreen extends StatefulWidget {
  final bool embedded;
  const DiscoverScreen({super.key, this.embedded = false});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final CropsDatabaseService _cropsService = CropsDatabaseService();

  List<String> _crops = [];
  List<String> _years = [];
  String? _selectedCrop;
  String? _selectedYear;

  Map<String, DistrictData> _districtDataMap = {};
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
        await _loadMapData();
      }
    } catch (e) {
      // ignore: empty_catches
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMapData() async {
    if (_selectedCrop == null || _selectedYear == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final districtData = await _cropsService.getDistrictDataForMap(
        _selectedCrop!,
        _selectedYear!,
      );

      // Convert to DistrictData format for the map
      final districtDataMap = <String, DistrictData>{};
      for (final entry in districtData.entries) {
        final district = entry.key;
        final data = entry.value;

        districtDataMap[district] = DistrictData(
          name: district,
          bnName: district,
          lat: 23.8103,
          long: 90.4125,
          production: (data['production'] as num? ?? 0).toDouble(),
          yieldValue: (data['yield'] as num? ?? 0).toDouble(),
          percentage: (data['percentage'] as num? ?? 0).toDouble(),
        );
      }

      setState(() {
        _districtDataMap = districtDataMap;
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
        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                                        ? const Center(
                                            child: Text('No results'),
                                          )
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
                                                onTap: () {
                                                  Navigator.of(ctx).pop(crop);
                                                },
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
                              ? (locale.languageCode == 'bn'
                                    ? 'কোনো ফসল নির্বাচন করা হয়নি'
                                    : 'Select crop')
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
                underline: Container(
                  height: 2,
                  color: const Color.fromARGB(255, 0, 77, 64),
                ),
                items: _years.map((year) {
                  final displayYear = TranslationHelper.formatNumber(
                    year,
                    useBengaliNumerals: locale.languageCode == 'bn',
                  );
                  return DropdownMenuItem(
                    value: year,
                    child: Text(displayYear),
                  );
                }).toList(),
                onChanged: (year) {
                  if (year != null) {
                    setState(() {
                      _selectedYear = year;
                    });
                    _loadMapData();
                  }
                },
              ),
              const SizedBox(height: 20),
              // Info Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hover over districts to see yield and percentage contribution',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Map
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_selectedCrop != null && _selectedYear != null)
                InteractiveBangladeshMap(
                  selectedCrop: _selectedCrop!,
                  districtDataMap: {_selectedCrop!: _districtDataMap},
                ),
            ],
          ),
        );

        if (widget.embedded) {
          return body;
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 0, 77, 64),
            elevation: 0,
            title: Text(
              Translations.translate(locale, 'discover'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: body,
        );
      },
    );
  }
}
