import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:summon_ai/model/ai_model.dart';
import 'package:summon_ai/view_model/ai_view_model.dart';

class SummonAIView extends StatefulWidget {
  final AIViewModel viewModel;
  final User user;
  final Future<void> Function() onSignOut;

  const SummonAIView({
    super.key,
    required this.viewModel,
    required this.user,
    required this.onSignOut,
  });

  @override
  State<SummonAIView> createState() => _SummonAIViewState();
}

class _SummonAIViewState extends State<SummonAIView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _cardController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  bool _punchlineRevealed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );

    _cardSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOut),
    );

    widget.viewModel.addListener(_onViewModelChange);
  }

  void _onViewModelChange() {
    if (!widget.viewModel.isLoading && widget.viewModel.currentJoke != null) {
      _punchlineRevealed = false;
      _cardController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cardController.dispose();
    widget.viewModel.removeListener(_onViewModelChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 24),
                      _buildHeroSection(),
                      const SizedBox(height: 32),
                      _buildSummonButton(),
                      const SizedBox(height: 24),
                      if (widget.viewModel.errorMessage != null)
                        _buildErrorCard(),
                      if (widget.viewModel.currentJoke != null &&
                          !widget.viewModel.isLoading)
                        _buildJokeCard(widget.viewModel.currentJoke!),
                      if (widget.viewModel.jokeHistory.length > 1)
                        _buildHistorySection(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // App Bar
  // ──────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FBE), Color(0xFF4776E6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Summon AI',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        Tooltip(
          message: widget.user.email ?? 'Signed in',
          child: CircleAvatar(
            radius: 14,
            backgroundImage: widget.user.photoURL == null
                ? null
                : NetworkImage(widget.user.photoURL!),
            child: widget.user.photoURL == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        if (widget.viewModel.jokeHistory.isNotEmpty)
          IconButton(
            onPressed: () {
              widget.viewModel.clearHistory();
              _cardController.reset();
            },
            icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFB0B0C8)),
            tooltip: 'Clear history',
          ),
        IconButton(
          onPressed: widget.onSignOut,
          icon: const Icon(Icons.logout_rounded, color: Color(0xFFB0B0C8)),
          tooltip: 'Sign out',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Hero / Header
  // ──────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FBE), Color(0xFF4776E6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B2FBE).withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.psychology_alt_rounded,
                size: 44, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Joke Generator',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the button to summon a fresh joke\nstraight from the AI universe.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Summon Button
  // ──────────────────────────────────────────────
  Widget _buildSummonButton() {
    final isLoading = widget.viewModel.isLoading;
    return Center(
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () async {
                await widget.viewModel.fetchAIResponse();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
          decoration: BoxDecoration(
            gradient: isLoading
                ? const LinearGradient(
                    colors: [Color(0xFF3A3A5C), Color(0xFF2A2A44)])
                : const LinearGradient(
                    colors: [Color(0xFF7B2FBE), Color(0xFF4776E6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: isLoading
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF7B2FBE).withValues(alpha: 0.45),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Summon a Joke',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Joke Card (main)
  // ──────────────────────────────────────────────
  Widget _buildJokeCard(AIResponseModel joke) {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: _JokeCard(
          joke: joke,
          isNew: true,
          punchlineRevealed: _punchlineRevealed,
          onReveal: () => setState(() => _punchlineRevealed = true),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Error Card
  // ──────────────────────────────────────────────
  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1020),
        border: Border.all(color: const Color(0xFFBE2F4A).withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFF6B8A), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.viewModel.errorMessage!,
              style: const TextStyle(color: Color(0xFFFF6B8A), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // History Section
  // ──────────────────────────────────────────────
  Widget _buildHistorySection() {
    final history = widget.viewModel.jokeHistory.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Row(
          children: [
            const Icon(Icons.history_rounded,
                color: Color(0xFFB0B0C8), size: 18),
            const SizedBox(width: 8),
            Text(
              'Previous Jokes (${history.length})',
              style: const TextStyle(
                color: Color(0xFFB0B0C8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...history.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _JokeCard(
                  joke: e.value,
                  isNew: false,
                  punchlineRevealed: true,
                  onReveal: () {},
                ),
              ),
            ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Reusable Joke Card Widget
// ──────────────────────────────────────────────────────────────────
class _JokeCard extends StatelessWidget {
  final AIResponseModel joke;
  final bool isNew;
  final bool punchlineRevealed;
  final VoidCallback onReveal;

  const _JokeCard({
    required this.joke,
    required this.isNew,
    required this.punchlineRevealed,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isNew
            ? const LinearGradient(
                colors: [Color(0xFF1A1A35), Color(0xFF15152A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isNew ? null : const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNew
              ? const Color(0xFF7B2FBE).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: isNew
            ? [
                BoxShadow(
                  color: const Color(0xFF7B2FBE).withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Setup
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2FBE).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.format_quote_rounded,
                      color: Color(0xFFB47EFF), size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    joke.setup,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: isNew ? 0.95 : 0.7),
                      fontSize: isNew ? 16 : 14,
                      fontWeight:
                          isNew ? FontWeight.w600 : FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 16),

            // Punchline or reveal button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: punchlineRevealed
                  ? Row(
                      key: const ValueKey('punchline'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4776E6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.emoji_emotions_rounded,
                              color: Color(0xFF7EAEFF), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            joke.punchline,
                            style: TextStyle(
                              color: const Color(0xFFB47EFF)
                                  .withValues(alpha: isNew ? 1 : 0.75),
                              fontSize: isNew ? 15 : 13,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      key: const ValueKey('reveal'),
                      onTap: onReveal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4776E6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF4776E6).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.visibility_rounded,
                                color: Color(0xFF7EAEFF), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Tap to reveal punchline',
                              style: TextStyle(
                                color: Color(0xFF7EAEFF),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
