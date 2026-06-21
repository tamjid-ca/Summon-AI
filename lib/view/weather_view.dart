import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:summon_ai/model/weather_model.dart';
import 'package:summon_ai/view_model/weather_view_model.dart';

class WeatherView extends StatefulWidget {
  final WeatherViewModel viewModel;
  final User user;
  final Future<void> Function() onSignOut;

  const WeatherView({
    super.key,
    required this.viewModel,
    required this.user,
    required this.onSignOut,
  });

  @override
  State<WeatherView> createState() => _WeatherViewState();
}

class _WeatherViewState extends State<WeatherView>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // Auto-fetch current location on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.viewModel.currentLocationWeather == null &&
          !widget.viewModel.isLoadingCurrent) {
        widget.viewModel.fetchCurrentLocation();
      }
    });

    widget.viewModel.addListener(_onViewModelChange);
  }

  void _onViewModelChange() {
    if (!widget.viewModel.isLoadingCurrent &&
        widget.viewModel.currentLocationWeather != null) {
      _fadeController.forward(from: 0);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    widget.viewModel.removeListener(_onViewModelChange);
    super.dispose();
  }

  void _search() {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    _searchFocus.unfocus();
    widget.viewModel.fetchWeatherByCity(q);
  }

  // ──────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Current Location Section ──
                      _sectionLabel('📍 My Location', trailing: _refreshButton()),
                      const SizedBox(height: 12),
                      _buildCurrentLocationCard(),
                      const SizedBox(height: 28),

                      // ── Search Section ──
                      _sectionLabel('🔍 Search Location'),
                      const SizedBox(height: 12),
                      _buildSearchBar(),
                      const SizedBox(height: 16),

                      // Search result
                      if (widget.viewModel.isLoadingSearch)
                        _buildSkeletonCard(),
                      if (widget.viewModel.searchErrorMessage != null)
                        _buildErrorCard(widget.viewModel.searchErrorMessage!),
                      if (widget.viewModel.searchedWeather != null &&
                          !widget.viewModel.isLoadingSearch)
                        _buildWeatherCard(widget.viewModel.searchedWeather!,
                            isHighlighted: true),

                      // ── Search History ──
                      if (widget.viewModel.savedLocations.length > 1) ...[
                        const SizedBox(height: 28),
                        _buildHistoryHeader(),
                        const SizedBox(height: 12),
                        ...widget.viewModel.savedLocations
                            .skip(1)
                            .map((w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildWeatherCard(w,
                                      isHighlighted: false),
                                )),
                      ],
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
                colors: [Color(0xFF4776E6), Color(0xFF11C5CF)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wb_sunny_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Weather',
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
        if (widget.viewModel.savedLocations.isNotEmpty)
          IconButton(
            onPressed: widget.viewModel.clearSavedLocations,
            icon: const Icon(Icons.delete_sweep_rounded,
                color: Color(0xFFB0B0C8)),
            tooltip: 'Clear search history',
          ),
        IconButton(
          onPressed: widget.onSignOut,
          icon: const Icon(Icons.logout_rounded,
              color: Color(0xFFB0B0C8)),
          tooltip: 'Sign out',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Section label
  // ──────────────────────────────────────────────

  Widget _sectionLabel(String label, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB0B0C8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  Widget _refreshButton() {
    return GestureDetector(
      onTap: widget.viewModel.isLoadingCurrent
          ? null
          : widget.viewModel.fetchCurrentLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              color: widget.viewModel.isLoadingCurrent
                  ? Colors.white24
                  : const Color(0xFF11C5CF),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Refresh',
              style: TextStyle(
                color: widget.viewModel.isLoadingCurrent
                    ? Colors.white24
                    : const Color(0xFF11C5CF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Current Location Card
  // ──────────────────────────────────────────────

  Widget _buildCurrentLocationCard() {
    if (widget.viewModel.isLoadingCurrent) return _buildSkeletonCard();

    if (widget.viewModel.errorMessage != null) {
      return _buildErrorCard(widget.viewModel.errorMessage!,
          onRetry: widget.viewModel.fetchCurrentLocation);
    }

    final w = widget.viewModel.currentLocationWeather;
    if (w == null) {
      return _buildPromptCard(
        icon: Icons.location_on_rounded,
        message: 'Tap Refresh to detect your location.',
        color: const Color(0xFF4776E6),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child:
          _buildWeatherCard(w, isHighlighted: true, isCurrentLocation: true),
    );
  }

  // ──────────────────────────────────────────────
  // Search Bar
  // ──────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'City name, e.g. London',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 15),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF4776E6), size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          widget.viewModel.clearSearch();
                          setState(() {});
                        },
                        child: const Icon(Icons.close_rounded,
                            color: Color(0xFFB0B0C8), size: 18),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _search,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4776E6), Color(0xFF11C5CF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4776E6).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // History Header
  // ──────────────────────────────────────────────

  Widget _buildHistoryHeader() {
    return Row(
      children: [
        const Icon(Icons.history_rounded, color: Color(0xFFB0B0C8), size: 16),
        const SizedBox(width: 6),
        Text(
          'Recent Searches (${widget.viewModel.savedLocations.length - 1})',
          style: const TextStyle(
            color: Color(0xFFB0B0C8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  // Main Weather Card
  // ──────────────────────────────────────────────

  Widget _buildWeatherCard(
    WeatherModel w, {
    required bool isHighlighted,
    bool isCurrentLocation = false,
  }) {
    final temp = w.current.temperature;
    final desc = w.current.primaryDescription;
    final isDay = w.current.isDay;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isHighlighted
            ? LinearGradient(
                colors: isCurrentLocation
                    ? [const Color(0xFF0F2B5B), const Color(0xFF0A1F3A)]
                    : [const Color(0xFF1A1A35), const Color(0xFF15152A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isHighlighted ? null : const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF4776E6).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFF4776E6).withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                )
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Location + Time Row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isCurrentLocation)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(Icons.location_on_rounded,
                                  color: Color(0xFF11C5CF), size: 14),
                            ),
                          Flexible(
                            child: Text(
                              w.location.name,
                              style: TextStyle(
                                color: Colors.white.withValues(
                                    alpha: isHighlighted ? 1.0 : 0.75),
                                fontSize: isHighlighted ? 18 : 15,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${w.location.country}  •  ${w.location.localtime}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Day/Night badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDay
                        ? const Color(0xFFFFA630).withValues(alpha: 0.15)
                        : const Color(0xFF6B7FD4).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDay
                            ? Icons.wb_sunny_rounded
                            : Icons.nightlight_round,
                        color: isDay
                            ? const Color(0xFFFFA630)
                            : const Color(0xFF6B7FD4),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isDay ? 'Day' : 'Night',
                        style: TextStyle(
                          color: isDay
                              ? const Color(0xFFFFA630)
                              : const Color(0xFF6B7FD4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(
                color: Colors.white.withValues(alpha: 0.07), height: 1),
            const SizedBox(height: 16),

            // ── Temperature + Condition ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$temp°',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isHighlighted ? 64 : 48,
                    fontWeight: FontWeight.w200,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        desc,
                        style: TextStyle(
                          color:
                              Colors.white.withValues(alpha: 0.85),
                          fontSize: isHighlighted ? 16 : 13,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Feels like ${w.current.feelslike}°C',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (isHighlighted) ...[
              const SizedBox(height: 20),
              // ── Stats Chips ──
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _statChip(Icons.water_drop_rounded,
                      '${w.current.humidity}%', 'Humidity',
                      const Color(0xFF4776E6)),
                  _statChip(Icons.air_rounded,
                      '${w.current.windSpeed} km/h', 'Wind',
                      const Color(0xFF11C5CF)),
                  _statChip(Icons.wb_sunny_outlined,
                      'UV ${w.current.uvIndex}', 'UV Index',
                      const Color(0xFFFFA630)),
                  _statChip(Icons.visibility_rounded,
                      '${w.current.visibility} km', 'Visibility',
                      const Color(0xFF9B59B6)),
                  _statChip(Icons.cloud_rounded,
                      '${w.current.cloudcover}%', 'Cloud',
                      const Color(0xFF5DADE2)),
                  _statChip(Icons.compress_rounded,
                      '${w.current.pressure} mb', 'Pressure',
                      const Color(0xFF48C9B0)),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              // Condensed chips for history cards
              Row(
                children: [
                  _miniChip(Icons.water_drop_rounded,
                      '${w.current.humidity}%', const Color(0xFF4776E6)),
                  const SizedBox(width: 8),
                  _miniChip(Icons.air_rounded,
                      '${w.current.windSpeed} km/h', const Color(0xFF11C5CF)),
                  const SizedBox(width: 8),
                  _miniChip(Icons.wb_sunny_outlined,
                      'UV ${w.current.uvIndex}', const Color(0xFFFFA630)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statChip(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.1),
              ),
              Text(
                label,
                style: TextStyle(
                    color: color.withValues(alpha: 0.65),
                    fontSize: 10,
                    height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Skeleton Loading Card
  // ──────────────────────────────────────────────

  Widget _buildSkeletonCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF4776E6),
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Fetching weather…',
              style: TextStyle(color: Color(0xFF6B6B8A), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Error Card
  // ──────────────────────────────────────────────

  Widget _buildErrorCard(String message, {VoidCallback? onRetry}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1020),
        border: Border.all(
            color: const Color(0xFFBE2F4A).withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFFF6B8A), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      color: Color(0xFFFF6B8A), fontSize: 13),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFBE2F4A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Try Again',
                    style: TextStyle(
                        color: Color(0xFFFF6B8A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Empty Prompt Card
  // ──────────────────────────────────────────────

  Widget _buildPromptCard(
      {required IconData icon,
      required String message,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.5), size: 36),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
