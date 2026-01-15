import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/my_crop.dart';
import '../providers/my_crops_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';
import '../services/crop_info_service.dart';

class CropDetailScreen extends StatefulWidget {
  final MyCrop crop;

  const CropDetailScreen({super.key, required this.crop});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  String? _aiInsight;
  String? _growthStage;
  String? _primaryRisk;
  String? _landManagementTip;
  bool _loadingInsight = false;
  bool _insightError = false;

  @override
  void initState() {
    super.initState();
    _fetchInsightIfNeeded();
  }

  Future<void> _fetchInsightIfNeeded() async {
    debugPrint(
      '🚀 Starting _fetchInsightIfNeeded for crop: ${widget.crop.cropName}',
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'insight_${widget.crop.id}';
      final lastFetchKey = 'insight_fetch_time_${widget.crop.id}';

      // Check if we have cached data and if it's still valid (< 1 hour old)
      final lastFetchTime = prefs.getInt(lastFetchKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final oneHourInMs = 60 * 60 * 1000;

      debugPrint(
        '⏰ Cache check: lastFetch=$lastFetchTime, now=$now, diff=${now - lastFetchTime}',
      );

      if (now - lastFetchTime < oneHourInMs) {
        // Use cached insight
        final cachedInsight = prefs.getString(cacheKey);
        debugPrint(
          '💾 Using cached insight: ${cachedInsight?.substring(0, cachedInsight.length > 50 ? 50 : cachedInsight.length)}...',
        );
        if (cachedInsight != null && mounted) {
          setState(() {
            _aiInsight = cachedInsight;
          });
          return;
        }
      }

      // Fetch new insight
      debugPrint('🌐 Fetching new insight from API...');
      if (mounted) {
        setState(() {
          _loadingInsight = true;
          _insightError = false;
        });
      }

      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      final lat = locationProvider.latitude ?? 23.8;
      final lon = locationProvider.longitude ?? 90.4;

      debugPrint('📍 Location: lat=$lat, lon=$lon');
      debugPrint(
        '📤 Request body: crop_name=${widget.crop.cropName}, days_sown=${widget.crop.daysSincePlanting}',
      );

      final response = await http
          .post(
            Uri.parse('https://cibarian-julee-hurtling.ngrok-free.dev/webhook/generate-insight'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'crop_name': widget.crop.cropName,
              'days_sown': widget.crop.daysSincePlanting,
              'land_area': '${widget.crop.landArea} ${widget.crop.landUnit}',
              'latitude': lat,
              'longitude': lon,
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📥 Response received: status=${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Response received with status 200');
        debugPrint('📦 Raw response body: ${response.body}');

        final data = jsonDecode(response.body);
        debugPrint('📊 Data type: ${data.runtimeType}');
        debugPrint('📊 Data content: $data');

        String insight = 'No insights available';

        try {
          // Handle n8n response format: array with nested structure
          if (data is List && data.isNotEmpty) {
            debugPrint('✅ Data is a List with ${data.length} items');
            final firstItem = data[0];
            debugPrint('📝 First item: $firstItem');

            final content = firstItem['content'];
            debugPrint('📝 Content: $content');

            final parts = content['parts'];
            debugPrint(
              '📝 Parts type: ${parts.runtimeType}, length: ${parts is List ? parts.length : "N/A"}',
            );

            if (parts is List && parts.isNotEmpty) {
              final textContent = parts[0]['text'];
              debugPrint('📄 Text content: $textContent');

              // Parse the nested JSON string
              final innerData = jsonDecode(textContent);
              debugPrint('🔍 Inner data parsed: $innerData');

              // Extract action_items array and format as string
              if (innerData['action_items'] != null) {
                final actionItems = innerData['action_items'] as List;
                debugPrint('✅ Action items found: ${actionItems.length} items');
                insight = actionItems.map((item) => '• $item').join('\n\n');
                debugPrint('✅ Final insight: $insight');
              } else {
                debugPrint('⚠️ No action_items in inner data');
              }
            }
          }
          // Fallback for simple response format
          else if (data is Map) {
            debugPrint('✅ Data is a Map, trying fallback parsing');

            // Extract all fields from the response
            String? growthStage = data['growth_stage']?.toString();
            String? primaryRisk = data['primary_risk']?.toString();
            String? landManagementTip = data['land_management_tip']?.toString();

            debugPrint('📝 Growth Stage: $growthStage');
            debugPrint('📝 Primary Risk: $primaryRisk');
            debugPrint('📝 Land Management Tip: $landManagementTip');

            // Check if action_items exists and is a List
            if (data['action_items'] != null) {
              final actionItems = data['action_items'];
              debugPrint('📝 action_items type: ${actionItems.runtimeType}');

              if (actionItems is List) {
                insight = actionItems.map((item) => '• $item').join('\n\n');
                debugPrint('✅ Formatted ${actionItems.length} action items');
              } else {
                insight = actionItems.toString();
                debugPrint('📝 action_items converted to string');
              }
            } else if (data['insight'] != null) {
              insight = data['insight'].toString();
              debugPrint('📝 Using insight field');
            } else {
              insight = 'No insights available';
              debugPrint('⚠️ No action_items or insight found in response');
            }

            // Store additional fields in state variables
            if (mounted) {
              setState(() {
                _growthStage = growthStage;
                _primaryRisk = primaryRisk;
                _landManagementTip = landManagementTip;
              });
            }

            debugPrint(
              '📝 Final fallback insight: ${insight.substring(0, insight.length > 100 ? 100 : insight.length)}...',
            );
          } else {
            debugPrint('❌ Data is neither List nor Map: ${data.runtimeType}');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Error parsing insight data: $e');
          debugPrint('❌ Stack trace: $stackTrace');
          insight = 'Failed to parse insights: $e';
        }

        // Cache the insight
        await prefs.setString(cacheKey, insight);
        await prefs.setInt(lastFetchKey, now);
        debugPrint('💾 Insight cached successfully');

        if (mounted) {
          setState(() {
            _aiInsight = insight;
            _loadingInsight = false;
          });
          debugPrint('✅ UI updated with insight');
        }
      } else {
        debugPrint('❌ Response status code: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        throw Exception('Failed to load insight: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌❌❌ OUTER CATCH - Error fetching AI insight: $e');
      debugPrint('❌❌❌ Error type: ${e.runtimeType}');
      debugPrint('❌❌❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _loadingInsight = false;
          _insightError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cropInfoService = CropInfoService();
    final cropInfo = cropInfoService.getCropInfo(widget.crop.cropName);
    final stageInfo = cropInfoService.getCurrentStageInfo(
      widget.crop.cropName,
      widget.crop.daysSincePlanting,
    );

    return Consumer<LocalizationProvider>(
      builder: (context, locProvider, child) {
        final isBangla = locProvider.locale.languageCode == 'bn';

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App Bar with crop image
              SliverAppBar(
                expandedHeight: 100,
                pinned: true,
                backgroundColor: theme.colorScheme.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    isBangla
                        ? (cropInfo?.nameBn ?? widget.crop.cropNameBn)
                        : _capitalizeFirstLetter(
                            cropInfo?.name ?? widget.crop.cropName,
                          ),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(context, isBangla);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(isBangla ? 'মুছে ফেলুন' : 'Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Insight Card
                      _buildAIInsightCard(context, theme, isBangla),
                      const SizedBox(height: 16),

                      // Progress Card
                      _buildProgressCard(context, theme, isBangla, stageInfo),
                      const SizedBox(height: 16),

                      // Key Stats
                      _buildStatsRow(context, theme, isBangla),
                      const SizedBox(height: 16),

                      // Current Stage Info
                      if (stageInfo != null)
                        _buildStageCard(context, theme, isBangla, stageInfo),
                      const SizedBox(height: 16),

                      // Care Recommendations
                      _buildCareCard(
                        context,
                        theme,
                        isBangla,
                        cropInfo,
                        stageInfo,
                      ),
                      const SizedBox(height: 16),

                      // Weather Warnings
                      _buildWeatherWarnings(context, theme, isBangla, cropInfo),
                      const SizedBox(height: 16),

                      // Crop Info
                      if (cropInfo != null)
                        _buildCropInfoCard(context, theme, isBangla, cropInfo),
                      const SizedBox(height: 16),

                      // Common Issues
                      if (cropInfo != null)
                        _buildCommonIssuesCard(
                          context,
                          theme,
                          isBangla,
                          cropInfo,
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAIInsightCard(
    BuildContext context,
    ThemeData theme,
    bool isBangla,
  ) {
    if (!_loadingInsight && _aiInsight == null && !_insightError) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1A237E).withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Color(0xFF1A237E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isBangla ? 'AI পরামর্শ' : 'AI Insights',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                ),
                if (!_loadingInsight && _aiInsight != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    color: const Color(0xFF1A237E),
                    onPressed: () async {
                      // Force refresh by clearing cache
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove(
                        'insight_fetch_time_${widget.crop.id}',
                      );
                      await _fetchInsightIfNeeded();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingInsight)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isBangla
                          ? 'AI পরামর্শ তৈরি করা হচ্ছে...'
                          : 'Generating AI insights...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            else if (_insightError)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isBangla
                            ? 'AI পরামর্শ লোড করতে ব্যর্থ হয়েছে। পরে আবার চেষ্টা করুন।'
                            : 'Failed to load AI insights. Please try again later.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_aiInsight != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Growth Stage & Primary Risk Row
                  if (_growthStage != null || _primaryRisk != null)
                    Row(
                      children: [
                        if (_growthStage != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.spa,
                                        size: 14,
                                        color: Colors.green[700],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isBangla
                                            ? 'বৃদ্ধি পর্যায়'
                                            : 'Growth Stage',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _growthStage!,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_growthStage != null && _primaryRisk != null)
                          const SizedBox(width: 12),
                        if (_primaryRisk != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 14,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isBangla
                                            ? 'প্রধান ঝুঁকি'
                                            : 'Primary Risk',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange[700],
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _primaryRisk!,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (_growthStage != null || _primaryRisk != null)
                    const SizedBox(height: 12),

                  // Action Items
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1A237E).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.checklist_rtl,
                              size: 16,
                              color: const Color(0xFF1A237E),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isBangla ? 'কর্ম পরিকল্পনা' : 'Action Items',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A237E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _aiInsight!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Land Management Tip
                  if (_landManagementTip != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1A237E).withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: const Color(0xFF1A237E),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBangla
                                      ? 'ভূমি ব্যবস্থাপনা টিপস'
                                      : 'Land Management Tip',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A237E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _landManagementTip!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    ThemeData theme,
    bool isBangla,
    StageInfo? stageInfo,
  ) {
    final progressPercent = (widget.crop.growthProgress * 100).toInt();
    Color progressColor = theme.colorScheme.primary;
    if (widget.crop.isReadyForHarvest) {
      progressColor = Colors.green;
    } else if (widget.crop.daysUntilHarvest <= 7) {
      progressColor = Colors.orange;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isBangla ? 'বৃদ্ধির অগ্রগতি' : 'Growth Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$progressPercent%',
                    style: TextStyle(
                      color: progressColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar with stages
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: widget.crop.growthProgress,
                    backgroundColor: progressColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stage indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStageIndicator(
                  isBangla ? 'অঙ্কুর' : 'Germ',
                  widget.crop.growthProgress >= 0.15,
                  progressColor,
                ),
                _buildStageIndicator(
                  isBangla ? 'বৃদ্ধি' : 'Veg',
                  widget.crop.growthProgress >= 0.35,
                  progressColor,
                ),
                _buildStageIndicator(
                  isBangla ? 'ফুল' : 'Flower',
                  widget.crop.growthProgress >= 0.55,
                  progressColor,
                ),
                _buildStageIndicator(
                  isBangla ? 'ফল' : 'Fruit',
                  widget.crop.growthProgress >= 0.80,
                  progressColor,
                ),
                _buildStageIndicator(
                  isBangla ? 'কাটা' : 'Harvest',
                  widget.crop.growthProgress >= 1.0,
                  progressColor,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current stage name
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isBangla
                      ? 'বর্তমান: ${stageInfo?.nameBn ?? widget.crop.getGrowthStageName(isBangla)}'
                      : 'Current: ${stageInfo?.name ?? widget.crop.getGrowthStageName(isBangla)}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageIndicator(String label, bool isActive, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : Colors.grey.withOpacity(0.3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: isActive ? color : Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, ThemeData theme, bool isBangla) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            isBangla ? 'রোপণের দিন' : 'Days Planted',
            '${widget.crop.daysSincePlanting}',
            Icons.calendar_today,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            isBangla ? 'বাকি দিন' : 'Days Left',
            widget.crop.isReadyForHarvest
                ? (isBangla ? 'প্রস্তুত!' : 'Ready!')
                : '${widget.crop.daysUntilHarvest}',
            Icons.timer,
            widget.crop.isReadyForHarvest ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            isBangla ? 'জমি' : 'Area',
            '${widget.crop.landArea}',
            Icons.landscape,
            Colors.teal,
            subtitle: _getUnitLabel(widget.crop.landUnit, isBangla),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard(
    BuildContext context,
    ThemeData theme,
    bool isBangla,
    StageInfo stageInfo,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isBangla ? 'বর্তমান পর্যায়ের যত্ন' : 'Current Stage Care',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Text(
                isBangla ? stageInfo.careBn : stageInfo.care,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),

            // Warnings
            if ((isBangla ? stageInfo.warningsBn : stageInfo.warnings)
                .isNotEmpty) ...[
              Text(
                isBangla ? '⚠️ সতর্কতা:' : '⚠️ Warnings:',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(height: 8),
              ...(isBangla ? stageInfo.warningsBn : stageInfo.warnings).map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warning,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCareCard(
    BuildContext context,
    ThemeData theme,
    bool isBangla,
    CropInfo? cropInfo,
    StageInfo? stageInfo,
  ) {
    if (cropInfo == null) return const SizedBox.shrink();

    final careTopics = isBangla ? cropInfo.careTopicsBn : cropInfo.careTopics;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Text(
                  isBangla ? 'যত্নের বিষয়' : 'Care Topics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: careTopics.map((topic) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Text(
                    topic,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherWarnings(
    BuildContext context,
    ThemeData theme,
    bool isBangla,
    CropInfo? cropInfo,
  ) {
    if (cropInfo == null) return const SizedBox.shrink();

    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weather = weatherProvider.weatherData;

    final cropInfoService = CropInfoService();
    final warnings = cropInfoService.getWeatherBasedWarnings(
      widget.crop.cropName,
      widget.crop.daysSincePlanting,
      currentTemp: weather?.currentTemp,
      precipitation: weather?.dailyForecasts.isNotEmpty == true
          ? weather!.dailyForecasts.first.precipitationProbability.toDouble()
          : null,
      isBangla: isBangla,
    );

    if (warnings.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.orange.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.warning_amber, color: Colors.orange[700]),
                ),
                const SizedBox(width: 12),
                Text(
                  isBangla ? 'আবহাওয়া সতর্কতা' : 'Weather Alerts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...warnings.map((warning) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getWarningIcon(warning['icon']),
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        warning['message'],
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _getWarningIcon(String? iconName) {
    switch (iconName) {
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'water_drop':
        return Icons.water_drop;
      default:
        return Icons.info;
    }
  }

  Widget _buildCropInfoCard(
    BuildContext context,
    ThemeData theme,
    bool isBangla,
    CropInfo cropInfo,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  isBangla ? 'ফসলের তথ্য' : 'Crop Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              theme,
              isBangla ? 'মৌসুম' : 'Season',
              isBangla ? cropInfo.seasonBn : cropInfo.season,
              Icons.calendar_month,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              theme,
              isBangla ? 'সময়কাল' : 'Duration',
              isBangla
                  ? '${cropInfo.growthDurationDays} দিন'
                  : '${cropInfo.growthDurationDays} days',
              Icons.timer,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              theme,
              isBangla ? 'আদর্শ তাপমাত্রা' : 'Optimal Temp',
              cropInfo.optimalTemp,
              Icons.thermostat,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              theme,
              isBangla ? 'পানির চাহিদা' : 'Water Need',
              '${cropInfo.waterRequirement.toInt()} mm/${isBangla ? 'সপ্তাহ' : 'week'}',
              Icons.water_drop,
            ),
            const SizedBox(height: 12),

            Text(
              isBangla ? cropInfo.descriptionBn : cropInfo.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
      ],
    );
  }

  Widget _buildCommonIssuesCard(
    BuildContext context,
    ThemeData theme,
    bool isBangla,
    CropInfo cropInfo,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bug_report, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Text(
                  isBangla ? 'সাধারণ সমস্যা' : 'Common Issues',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              isBangla ? '🦠 রোগ:' : '🦠 Diseases:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cropInfo.commonDiseases.map((disease) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    disease,
                    style: TextStyle(fontSize: 11, color: Colors.red[700]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            Text(
              isBangla ? '🐛 পোকা:' : '🐛 Pests:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cropInfo.commonPests.map((pest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pest,
                    style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getUnitLabel(String unit, bool isBangla) {
    switch (unit) {
      case 'hectare':
        return isBangla ? 'হেক্টর' : 'hectare';
      case 'bigha':
        return isBangla ? 'বিঘা' : 'bigha';
      case 'acre':
        return isBangla ? 'একর' : 'acre';
      case 'decimal':
        return isBangla ? 'ডেসিমেল' : 'decimal';
      default:
        return unit;
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showDeleteDialog(BuildContext context, bool isBangla) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBangla ? 'ফসল মুছে ফেলবেন?' : 'Delete Crop?'),
        content: Text(
          isBangla
              ? 'এই ফসলটি মুছে ফেলা হবে। এটি পূর্বাবস্থায় ফেরানো যাবে না।'
              : 'This crop will be deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isBangla ? 'বাতিল' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<MyCropsProvider>(
                context,
                listen: false,
              ).removeCrop(widget.crop.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
            },
            child: Text(
              isBangla ? 'মুছুন' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
