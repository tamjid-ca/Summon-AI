import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:summon_ai/model/chat_message.dart';
import 'package:summon_ai/view_model/gemini_chat_view_model.dart';

class GeminiChatOverlay extends StatefulWidget {
  final GeminiChatViewModel viewModel;
  final VoidCallback onClose;

  const GeminiChatOverlay({
    super.key,
    required this.viewModel,
    required this.onClose,
  });

  @override
  State<GeminiChatOverlay> createState() => _GeminiChatOverlayState();
}

class _GeminiChatOverlayState extends State<GeminiChatOverlay>
    with TickerProviderStateMixin {
  late AnimationController _portalRotationController;
  late AnimationController _portalPulseController;
  late AnimationController _fadeTransitionController;

  late Animation<double> _portalRotation;
  late Animation<double> _portalPulse;
  late Animation<double> _overlayFade;

  bool _isSummoning = true;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    "Tell me an interesting tech fact",
    "Explain quantum computing in simple terms",
    "Write a short, inspiring poem about stars",
    "Give me 3 creative business ideas",
  ];

  @override
  void initState() {
    super.initState();

    // Portal rotation: continuous rotation
    _portalRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _portalRotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _portalRotationController,
        curve: Curves.linear,
      ),
    );

    // Portal pulsing: scale up/down
    _portalPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _portalPulse = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _portalPulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Transition controller: handling overall entry/exit fades
    _fadeTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _overlayFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeTransitionController,
        curve: Curves.easeOut,
      ),
    );

    // Fade in overlay on start
    _fadeTransitionController.forward();

    // Complete summoning phase after 2 seconds
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _isSummoning = false;
        });
      }
    });

    widget.viewModel.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _portalRotationController.dispose();
    _portalPulseController.dispose();
    _fadeTransitionController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    widget.viewModel.removeListener(_scrollToBottom);
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0, // Since list is reversed, 0 is the bottom (newest items)
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    widget.viewModel.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _overlayFade,
      builder: (context, child) {
        return Opacity(
          opacity: _overlayFade.value,
          child: Stack(
            children: [
              // 1. Frosted Glass Background covering whole screen
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: const Color(0xFF070714).withValues(alpha: 0.85),
                  ),
                ),
              ),

              // 2. Main content based on state
              Positioned.fill(
                child: SafeArea(
                  child: _isSummoning
                      ? _buildSummoningCircle()
                      : _buildChatInterface(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Summoning Circle Widget
  // ──────────────────────────────────────────────
  Widget _buildSummoningCircle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glowing circle
                ScaleTransition(
                  scale: _portalPulse,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B2FBE).withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFF4776E6).withValues(alpha: 0.2),
                          blurRadius: 60,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),

                // Rotating Magic Runes Ring
                AnimatedBuilder(
                  animation: _portalRotation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _portalRotation.value,
                      child: CustomPaint(
                        size: const Size(200, 200),
                        painter: _PortalRingsPainter(),
                      ),
                    );
                  },
                ),

                // Counter-rotating Inner Ring
                AnimatedBuilder(
                  animation: _portalRotation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_portalRotation.value * 1.5,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF4776E6).withValues(alpha: 0.5),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Stack(
                          children: List.generate(4, (index) {
                            final angle = (index * 90) * math.pi / 180;
                            return Align(
                              alignment: Alignment(
                                math.cos(angle) * 0.9,
                                math.sin(angle) * 0.9,
                              ),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00F2FE),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),

                // Inner core pulsing brain / spark icon
                ScaleTransition(
                  scale: _portalPulse,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF7B2FBE), Color(0xFF00F2FE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'SUMMONING GEMINI AI',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Connecting to the neural core...',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Interactive Chat Interface
  // ──────────────────────────────────────────────
  Widget _buildChatInterface() {
    return Column(
      children: [
        _buildChatHeader(),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              final messages = widget.viewModel.messages;

              if (messages.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true, // Newer messages at the bottom
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: messages.length + (widget.viewModel.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // If we need to show the loading indicator
                  if (widget.viewModel.isLoading && index == 0) {
                    return _buildTypingIndicator();
                  }

                  // Normal message logic
                  final messageIndex =
                      widget.viewModel.isLoading ? index - 1 : index;
                  final message = messages[messages.length - 1 - messageIndex];

                  return _buildChatBubble(message);
                },
              );
            },
          ),
        ),
        if (widget.viewModel.errorMessage != null) _buildErrorBar(),
        _buildChatInput(),
      ],
    );
  }

  // Header of Chat Window
  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FBE), Color(0xFF4776E6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B2FBE).withValues(alpha: 0.3),
                  blurRadius: 10,
                )
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gemini AI Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              widget.viewModel.clearChat();
            },
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            tooltip: "Reset Conversation",
          ),
          IconButton(
            onPressed: () {
              _fadeTransitionController.reverse().then((_) {
                widget.onClose();
              });
            },
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
            ),
            tooltip: "Dismiss",
          ),
        ],
      ),
    );
  }

  // Welcome state with suggestions
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7B2FBE).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFF7B2FBE).withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: Color(0xFF9d58fc),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Portal Open',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How can I help you today? Summon a topic or query, and Gemini will assist.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Suggestions:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._suggestions.map((suggestion) {
              return Card(
                color: const Color(0xFF1E1E35).withValues(alpha: 0.6),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _handleSendMessage(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF4776E6),
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Error Alert Banner
  Widget _buildErrorBar() {
    return Container(
      width: double.infinity,
      color: Colors.redAccent.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        widget.viewModel.errorMessage ?? '',
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Chat Bubble Widget
  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isFromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF7B2FBE), Color(0xFF5B1F9E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : const Color(0xFF1E1E35).withValues(alpha: 0.85),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
        ),
        child: isUser
            ? SelectableText(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              )
            : MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                  h1: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.6),
                  h2: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
                  h3: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.5),
                  code: TextStyle(
                    color: const Color(0xFF00F2FE),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    fontFamily: 'monospace',
                    fontSize: 13.5,
                  ),
                  codeblockPadding: const EdgeInsets.all(12),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFF070714),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF7B2FBE), width: 3),
                    ),
                  ),
                  listBullet: const TextStyle(color: Color(0xFF00F2FE), fontSize: 14.5),
                ),
              ),
      ),
    );
  }

  // Bouncing dots typing indicator
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E35).withValues(alpha: 0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 14,
              color: Color(0xFF00F2FE),
            ),
            const SizedBox(width: 8),
            const Text(
              'Gemini is thinking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const _BouncingDotsOverlay(),
          ],
        ),
      ),
    );
  }

  // Text Input field at the bottom
  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF070714).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Ask Gemini anything...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                filled: true,
                fillColor: const Color(0xFF15152D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: const Color(0xFF7B2FBE).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              onSubmitted: _handleSendMessage,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _handleSendMessage(_inputController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF7B2FBE), Color(0xFF4776E6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BouncingDotsOverlay extends StatefulWidget {
  const _BouncingDotsOverlay();

  @override
  State<_BouncingDotsOverlay> createState() => _BouncingDotsOverlayState();
}

class _BouncingDotsOverlayState extends State<_BouncingDotsOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            double progress = (_controller.value - delay) % 1.0;
            double scale = 0.4 + 0.6 * math.sin(progress * math.pi);
            if (scale < 0.4) scale = 0.4;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: scale),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Custom Painter for magic runes / summoning circles
// ──────────────────────────────────────────────────────────────────
class _PortalRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintOuter = Paint()
      ..color = const Color(0xFF7B2FBE).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final paintInner = Paint()
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw main outer circle
    canvas.drawCircle(center, radius - 10, paintOuter);

    // Draw inner circle
    canvas.drawCircle(center, radius - 25, paintInner);

    // Draw custom rune tick lines around the outer circle
    final numTicks = 24;
    for (int i = 0; i < numTicks; i++) {
      final angle = (i * 360 / numTicks) * math.pi / 180;
      final start = Offset(
        center.dx + (radius - 18) * math.cos(angle),
        center.dy + (radius - 18) * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 8) * math.cos(angle),
        center.dy + (radius - 8) * math.sin(angle),
      );
      canvas.drawLine(start, end, paintOuter);
    }

    // Draw some triangles inside to create a pentagram-like geometric effect
    final numTriangles = 3;
    final path = Path();
    for (int i = 0; i < numTriangles; i++) {
      final angle1 = (i * 360 / numTriangles) * math.pi / 180;
      final angle2 = ((i * 360 / numTriangles) + 120) * math.pi / 180;
      final pt1 = Offset(
        center.dx + (radius - 25) * math.cos(angle1),
        center.dy + (radius - 25) * math.sin(angle1),
      );
      final pt2 = Offset(
        center.dx + (radius - 25) * math.cos(angle2),
        center.dy + (radius - 25) * math.sin(angle2),
      );
      path.moveTo(pt1.dx, pt1.dy);
      path.lineTo(pt2.dx, pt2.dy);
    }
    canvas.drawPath(path, paintInner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
