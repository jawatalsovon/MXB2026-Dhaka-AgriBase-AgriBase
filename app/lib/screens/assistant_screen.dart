import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/localization_provider.dart';
import '../services/ai_router.dart';
import '../services/rag_service.dart';
import '../utils/translations.dart';

class AssistantScreen extends StatefulWidget {
  final String? initialQuery;
  const AssistantScreen({super.key, this.initialQuery});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  late RAGService _ragService;

  @override
  void initState() {
    super.initState();
    _initializeRAG();
    // Pre-fill the text field if initialQuery is provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      // Optionally auto-send after a brief delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _controller.text.isNotEmpty) {
            _send();
          }
        });
      });
    }
  }

  void _initializeRAG() {
    _ragService = RAGService();
    // Initialize with default agricultural documents
    _ragService.initialize([
      Document(
        id: '1',
        content:
            'Rice is the primary staple crop of Bangladesh. Key growing seasons include Aman (monsoon), Boro (winter), and Aus (spring). Rice requires 120-150 days to mature and needs adequate water and nitrogen fertilizer.',
        source: 'Rice Cultivation Guide',
      ),
      Document(
        id: '2',
        content:
            'Wheat cultivation in Bangladesh starts in October-November. It requires cooler weather and less water than rice. Wheat yields 2-3 tons per hectare. Common varieties include BARI Gom-26.',
        source: 'Wheat Cultivation Guide',
      ),
      Document(
        id: '3',
        content:
            'Potato is grown primarily in winter season (October-March). It requires well-drained soil and moderate irrigation. Yield ranges from 15-20 tons per hectare. Seed rate is 2-2.5 tons per hectare.',
        source: 'Potato Cultivation Guide',
      ),
      Document(
        id: '4',
        content:
            'Soil health is critical for sustainable farming. Organic matter content should be maintained between 3-5%. Regular soil testing helps determine pH level and nutrient status. pH of 6.5-7.5 is optimal for most crops.',
        source: 'Soil Management Guide',
      ),
      Document(
        id: '5',
        content:
            'Crop rotation is an effective way to maintain soil health and manage pests. A good rotation might be: Rice-Wheat-Legume. Legumes like lentil and chickpea help fix nitrogen in soil.',
        source: 'Crop Rotation Systems Guide',
      ),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _controller.clear();
    });

    try {
      // Get RAG context for enhanced response
      final ragContext = await _ragService.retrieveContext(text);

      if (!mounted) return;

      final router = AiRouter.instance;
      final locale = Provider.of<LocalizationProvider>(
        context,
        listen: false,
      ).locale;

      // If RAG found relevant documents, use them to enhance the prompt
      String enhancedQuestion = text;
      if (ragContext.relevantDocs.isNotEmpty) {
        enhancedQuestion = await _ragService.buildRAGPrompt(text);
      }

      if (!mounted) return;

      final res = await router.handleUserMessage(
        enhancedQuestion,
        locale: locale,
      );
      setState(() {
        _messages.add(
          _ChatMessage(
            text: res.answer,
            isUser: false,
            sqlUsed: res.sqlUsed,
            hasRAGContext: ragContext.relevantDocs.isNotEmpty,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          _ChatMessage(
            text: 'Something went wrong while talking to the assistant: $e',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _pasteQuestion(String question) {
    _controller.text = question;
  }

  Widget _buildQuestionButton(String question) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pasteQuestion(question),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A237E).withValues(alpha: 0.1),
                const Color(0xFF4A148C).withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF1A237E).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: Color(0xFF1A237E),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocalizationProvider>(context).locale;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.psychology, size: 20),
            const SizedBox(width: 8),
            Text(Translations.translate(locale, 'agribaseAiAssistant')),
          ],
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF311B92), Color(0xFF4A148C)],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A237E).withValues(alpha: 0.05),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A237E).withValues(alpha: 0.1),
                    const Color(0xFF4A148C).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Translations.translate(locale, 'askQuestionsLike'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuestionButton(
                        Translations.translate(locale, 'cropDidBest'),
                      ),
                      _buildQuestionButton(
                        Translations.translate(locale, 'irrigateAmanRice'),
                      ),
                      _buildQuestionButton(
                        Translations.translate(locale, 'yieldStatisticsBoro'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A237E), Color(0xFF4A148C)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1A237E,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.psychology,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Ask me anything!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A237E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'I can help with crop data, farming tips,\nand agricultural insights',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg.isUser;
                        final alignment = isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft;

                        return Align(
                          alignment: alignment,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 4,
                            ),
                            child: Column(
                              crossAxisAlignment: isUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isUser
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF1A237E),
                                              Color(0xFF311B92),
                                            ],
                                          )
                                        : null,
                                    color: isUser
                                        ? null
                                        : isDark
                                        ? theme
                                              .colorScheme
                                              .surfaceContainerHighest
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(
                                        isUser ? 20 : 4,
                                      ),
                                      bottomRight: Radius.circular(
                                        isUser ? 4 : 20,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isUser
                                            ? const Color(
                                                0xFF1A237E,
                                              ).withValues(alpha: 0.3)
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isUser
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (!isUser && msg.hasRAGContext)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.auto_awesome,
                                                size: 12,
                                                color: const Color(0xFF1A237E),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'RAG Enhanced',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF1A237E,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Text(
                                        msg.text,
                                        style: TextStyle(
                                          color: isUser
                                              ? Colors.white
                                              : theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      if (msg.sqlUsed != null)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: isUser ? 0.2 : 0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color:
                                                  (isUser
                                                          ? Colors.white
                                                          : Colors.grey)
                                                      .withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.code,
                                                    size: 12,
                                                    color: isUser
                                                        ? Colors.white
                                                              .withValues(
                                                                alpha: 0.7,
                                                              )
                                                        : Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'SQL Query',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isUser
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.7,
                                                                )
                                                          : Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                msg.sqlUsed!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'monospace',
                                                  color: isUser
                                                      ? Colors.white.withValues(
                                                          alpha: 0.9,
                                                        )
                                                      : Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI is thinking...',
                      style: TextStyle(
                        color: const Color(0xFF1A237E),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1A237E).withValues(alpha: 0.05),
                              const Color(0xFF4A148C).withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(
                              0xFF1A237E,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: Translations.translate(
                              locale,
                              'askAiPrompt',
                            ),
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: _isLoading
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF1A237E), Color(0xFF311B92)],
                              ),
                        color: _isLoading ? Colors.grey[300] : null,
                        shape: BoxShape.circle,
                        boxShadow: _isLoading
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1A237E,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded),
                        color: _isLoading ? Colors.grey[500] : Colors.white,
                        onPressed: _isLoading ? null : _send,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  _ChatMessage({
    required this.text,
    required this.isUser,
    this.sqlUsed,
    this.hasRAGContext = false,
  });

  final String text;
  final bool isUser;
  final String? sqlUsed;
  final bool hasRAGContext;
}
