import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/crops_database_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../utils/data_utils.dart';
import '../providers/localization_provider.dart';
import '../utils/translations.dart';
import '../utils/translation_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  final bool embedded;
  const AnalyticsScreen({super.key, this.embedded = false});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final CropsDatabaseService _cropsService = CropsDatabaseService();

  static const List<Color> _pieColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
  ];

  List<String> _crops = [];
  List<String> _districts = [];
  List<String> _displayDistricts = [];
  String? _selectedCrop;
  String? _selectedDistrict;
  String? _selectedDisplayDistrict;

  List<Map<String, dynamic>> _yieldByYears = [];
  List<Map<String, dynamic>> _pieCropArea = [];
  List<Map<String, dynamic>> _pieFibreArea = [];
  List<Map<String, dynamic>> _pieNarcosArea = [];
  List<Map<String, dynamic>> _pieOilseedArea = [];
  List<Map<String, dynamic>> _piePulseArea = [];
  List<Map<String, dynamic>> _pieRiceArea = [];
  List<Map<String, dynamic>> _pieSpicesArea = [];
  List<Map<String, dynamic>> _pieSugerArea = [];
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
      final districts = await _cropsService.getAllDistricts();
      final displayDistricts = districts.map(cleanDistrict).toSet().toList()
        ..sort();
      final pieCropArea = await _cropsService.getPieCropArea();
      final pieFibreArea = await _cropsService.getPieFibreArea();
      final pieNarcosArea = await _cropsService.getPieNarcosArea();
      final pieOilseedArea = await _cropsService.getPieOilseedArea();
      final piePulseArea = await _cropsService.getPiePulseArea();
      final pieRiceArea = await _cropsService.getPieRiceArea();
      final pieSpicesArea = await _cropsService.getPieSpicesArea();
      final pieSugerArea = await _cropsService.getPieSugerArea();

      setState(() {
        _crops = crops;
        _districts = districts;
        _displayDistricts = displayDistricts;
        _pieCropArea = pieCropArea;
        _pieFibreArea = pieFibreArea;
        _pieNarcosArea = pieNarcosArea;
        _pieOilseedArea = pieOilseedArea;
        _piePulseArea = piePulseArea;
        _pieRiceArea = pieRiceArea;
        _pieSpicesArea = pieSpicesArea;
        _pieSugerArea = pieSugerArea;
        if (crops.isNotEmpty) _selectedCrop = crops.first;
        if (districts.isNotEmpty) {
          _selectedDistrict = districts.firstWhere(
            (d) => cleanDistrict(d) == displayDistricts.first,
          );
          _selectedDisplayDistrict = displayDistricts.first;
        }
      });

      if (_selectedCrop != null && _selectedDistrict != null) {
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
    if (_selectedCrop == null || _selectedDistrict == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final yieldData = await _cropsService.getYieldByYears(
        _selectedCrop!,
        _selectedDistrict!,
      );
      setState(() {
        _yieldByYears = yieldData;
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
    final theme = Theme.of(context);
    final body = Consumer<LocalizationProvider>(
      builder: (context, localizationProvider, child) {
        final locale = localizationProvider.locale;
        return SingleChildScrollView(
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
                                      hintText: 'Search crop',
                                    ),
                                    onChanged: (q) {
                                      setInner(() {
                                        results = _crops
                                            .where(
                                              (c) => c.toLowerCase().contains(
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
                    });
                    _loadData();
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
              const SizedBox(height: 20),
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
                                        ? const Center(
                                            child: Text('No results'),
                                          )
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
                                                onTap: () => Navigator.of(
                                                  ctx,
                                                ).pop(district),
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
                    });
                    _loadData();
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
              const SizedBox(height: 24),
              Text(
                Translations.translate(locale, 'yield'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_yieldByYears.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(Translations.translate(locale, 'noData')),
                  ),
                )
              else ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      primaryYAxis: NumericAxis(
                        title: const AxisTitle(text: 'Production (MT)'),
                      ),
                      series: <CartesianSeries>[
                        LineSeries<Map<String, dynamic>, String>(
                          dataSource: _yieldByYears,
                          xValueMapper: (data, _) =>
                              data['year'] as String? ?? '',
                          yValueMapper: (data, _) =>
                              (data['production_mt'] as num? ?? 0).toDouble(),
                          name: 'Production',
                          color: const Color.fromARGB(255, 0, 77, 64),
                          markerSettings: const MarkerSettings(isVisible: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Data Table
                Text(
                  Translations.translate(locale, 'yield'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              0,
                              77,
                              64,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Year',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Production (MT)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Yield (MT/Ha)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._yieldByYears.map((data) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    TranslationHelper.formatNumber(
                                      data['year'] as String? ?? '',
                                      useBengaliNumerals:
                                          locale.languageCode == 'bn',
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    TranslationHelper.formatNumberWithCommas(
                                      (data['production_mt'] as num? ?? 0)
                                          .toDouble(),
                                      decimalPlaces: 3,
                                      locale: locale,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    TranslationHelper.formatNumberWithCommas(
                                      (data['yield_per_hectare'] as num? ?? 0)
                                          .toDouble(),
                                      decimalPlaces: 3,
                                      locale: locale,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
              const Divider(height: 40),
              Text(
                Translations.translate(locale, 'area'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPieChart(
                    Translations.translate(locale, 'totalCropArea'),
                    _pieCropArea,
                    locale,
                  ),
                  _buildPieChart(
                    Translations.translate(locale, 'fibreArea'),
                    _pieFibreArea,
                    locale,
                  ),
                  _buildPieChart(
                    Translations.translate(locale, 'narcoticsArea'),
                    _pieNarcosArea,
                    locale,
                  ),
                  _buildPieChart(
                    Translations.translate(locale, 'oilseedsArea'),
                    _pieOilseedArea,
                    locale,
                  ),
                  _buildPieChart(
                    Translations.translate(locale, 'pulsesArea'),
                    _piePulseArea,
                    locale,
                  ),
                  _buildPieChart(
                    Translations.translate(locale, 'riceArea'),
                    _pieRiceArea,
                    locale,
                  ),
                  _buildPieChart(
                    Translations.translate(locale, 'spicesArea'),
                    _pieSpicesArea,
                    locale,
                  ),
                  _buildPieChart(
                    Translations.translate(locale, 'sugarcaneArea'),
                    _pieSugerArea,
                    locale,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 77, 64),
        elevation: 0,
        title: Consumer<LocalizationProvider>(
          builder: (context, localizationProvider, child) {
            return Text(
              Translations.translate(localizationProvider.locale, 'analytics'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
      body: body,
    );
  }

  Widget _buildPieChart(
    String title,
    List<Map<String, dynamic>> data,
    Locale locale,
  ) {
    final filteredData = data
        .where((d) => d['Category'] != null && d['Percentage'] != null)
        .toList();

    // Sort by percentage descending and take top 5
    final sortedData = List.from(filteredData)
      ..sort((a, b) {
        final percentA = (a['Percentage'] is num)
            ? (a['Percentage'] as num).toDouble()
            : double.tryParse(a['Percentage']?.toString() ?? '0') ?? 0.0;
        final percentB = (b['Percentage'] is num)
            ? (b['Percentage'] as num).toDouble()
            : double.tryParse(b['Percentage']?.toString() ?? '0') ?? 0.0;
        return percentB.compareTo(percentA);
      });

    final top5Data = sortedData.take(5).toList().cast<Map<String, dynamic>>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            top5Data.isEmpty
                ? const SizedBox(
                    height: 200,
                    child: Center(child: Text('No data available')),
                  )
                : Expanded(
                    child: SfCircularChart(
                      legend: const Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        overflowMode: LegendItemOverflowMode.wrap,
                      ),
                      series: <CircularSeries>[
                        PieSeries<Map<String, dynamic>, String>(
                          dataSource: top5Data,
                          xValueMapper: (datum, _) {
                            final category = datum['Category'] as String? ?? '';
                            return TranslationHelper.formatCropName(
                              category,
                              locale,
                            );
                          },
                          yValueMapper: (datum, _) {
                            final percentage = datum['Percentage'];
                            if (percentage is num) {
                              return percentage.toDouble();
                            }
                            return double.tryParse(
                                  percentage?.toString() ?? '0',
                                ) ??
                                0.0;
                          },
                          pointColorMapper: (datum, index) =>
                              _pieColors[index % _pieColors.length],
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            labelPosition: ChartDataLabelPosition.outside,
                            connectorLineSettings: const ConnectorLineSettings(
                              type: ConnectorType.line,
                              width: 2,
                            ),
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
}
