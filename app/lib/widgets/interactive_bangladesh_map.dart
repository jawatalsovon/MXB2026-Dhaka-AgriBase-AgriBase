import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_maps/maps.dart';
import 'package:provider/provider.dart';
import '../../models/district_data.dart';
import '../providers/localization_provider.dart';
import '../utils/translation_helper.dart';

// Ensure you have these dependencies in pubspec.yaml:
// syncfusion_flutter_maps: ^latest_version
// syncfusion_flutter_core: ^latest_version

// ============== Interactive Bangladesh Map (Selectable Version) ==============
class InteractiveBangladeshMap extends StatefulWidget {
  final String selectedCrop;
  final Map<String, Map<String, DistrictData>> districtDataMap;

  const InteractiveBangladeshMap({
    super.key,
    required this.selectedCrop,
    required this.districtDataMap,
  });

  @override
  State<InteractiveBangladeshMap> createState() =>
      _InteractiveBangladeshMapState();
}

class _InteractiveBangladeshMapState extends State<InteractiveBangladeshMap> {
  List<DistrictData> _dataList = [];
  MapShapeSource? _shapeSource;
  late MapZoomPanBehavior _zoomPanBehavior;

  // Track the currently selected district index
  int _selectedIndex = -1;

  // Min and max production values for UV map normalization
  double _minProduction = 0.0;
  double _maxProduction = 0.0;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = MapZoomPanBehavior(
      enableDoubleTapZooming: true,
      enablePanning: true,
      enablePinching: true,
      zoomLevel: 1.0,
      minZoomLevel: 1.0,
      maxZoomLevel: 10.0,
    );
    _updateMapSource();
  }

  @override
  void didUpdateWidget(covariant InteractiveBangladeshMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCrop != widget.selectedCrop ||
        oldWidget.districtDataMap != widget.districtDataMap) {
      _updateMapSource();
    }
  }

  void _updateMapSource() {
    final cropData = widget.districtDataMap[widget.selectedCrop] ?? {};
    _dataList = cropData.values.toList();

    // Calculate min and max production for UV map normalization
    if (_dataList.isNotEmpty) {
      _minProduction = _dataList
          .map((d) => d.production)
          .reduce((a, b) => a < b ? a : b);
      _maxProduction = _dataList
          .map((d) => d.production)
          .reduce((a, b) => a > b ? a : b);
      // Handle edge case where all values are the same
      if (_maxProduction == _minProduction) {
        _maxProduction = _minProduction + 1.0;
      }
    }

    // Reset selection when crop changes
    _selectedIndex = -1;
    _rebuildShapeSource();
  }

  void _rebuildShapeSource() {
    // Only create shape source if we have data
    if (_dataList.isEmpty) {
      return;
    }

    _shapeSource = MapShapeSource.asset(
      'assets/json/bd.geojson',

      // --- FIX IS HERE ---
      // Your JSON uses "adm2_name" for the district name (e.g. "Barguna")
      shapeDataField: 'adm2_name',

      // -------------------
      dataCount: _dataList.length,
      primaryValueMapper: (index) => _dataList[index].name,

      // UV Map Color Logic - White to Green gradient based on normalized values
      shapeColorValueMapper: (index) {
        if (index == _selectedIndex) {
          return const Color(0xFFFFD600); // Yellow when selected
        }

        final production = _dataList[index].production;

        // Normalize production value to 0-1 range
        final normalized =
            (production - _minProduction) / (_maxProduction - _minProduction);
        // Clamp to ensure it's between 0 and 1
        final clamped = normalized.clamp(0.0, 1.0);

        // Interpolate from white (0.0) to dark green (1.0)
        // White: Color(0xFFFFFFFF) -> Light Green -> Dark Green: Color(0xFF1B5E20)
        return Color.lerp(
              Colors.grey[300], // White
              const Color(0xFF1B5E20), // Dark Green
              clamped,
            ) ??
            const Color(0xFFA5D6A7); // Fallback to light green
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localizationProvider, child) {
        final locale = localizationProvider.locale;

        // Show loading/empty state if no data
        if (_dataList.isEmpty) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              height: 400,
              color: Colors.green[50],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      locale.languageCode == 'bn'
                          ? 'জেলার তথ্য লোড হচ্ছে...'
                          : 'Loading district data...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 400,
                color: Colors.green[50],
                child: _shapeSource == null
                    ? const Center(child: CircularProgressIndicator())
                    : SfMaps(
                        layers: [
                          MapShapeLayer(
                            source: _shapeSource!,
                            zoomPanBehavior: _zoomPanBehavior,

                            strokeColor: Colors.white,
                            strokeWidth: 0.6,
                            color: Colors
                                .grey[300], // Fallback color for unmatched districts
                            // --- SELECTION HANDLING ---
                            selectedIndex: _selectedIndex,
                            onSelectionChanged: (int index) {
                              setState(() {
                                // Toggle selection
                                if (_selectedIndex == index) {
                                  _selectedIndex =
                                      -1; // Deselect if tapped again
                                } else {
                                  _selectedIndex = index;
                                }
                                // Rebuild the source to apply the new "Yellow" color
                                _rebuildShapeSource();
                              });
                            },

                            // --- TOOLTIP REMOVED - info shown in panel below ---
                            showDataLabels: false,
                          ),
                        ],
                      ),
              ),

              // --- SELECTED DISTRICT INFO PANEL (Appears below map when selected) ---
              if (_selectedIndex != -1)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationHelper.formatDistrictName(
                          _dataList[_selectedIndex].name,
                          locale,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildInfoItem(
                            locale.languageCode == 'bn'
                                ? "উৎপাদন:"
                                : "Production:",
                            "${TranslationHelper.formatNumberWithCommas((_dataList[_selectedIndex].production / 1000), decimalPlaces: 3, locale: locale)}k MT",
                          ),
                          SizedBox(width: 16),
                          _buildInfoItem(
                            locale.languageCode == 'bn' ? "ফলন:" : "Yield:",
                            "${TranslationHelper.formatNumberWithCommas(_dataList[_selectedIndex].yieldValue, decimalPlaces: 3, locale: locale)} T/Ha",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
