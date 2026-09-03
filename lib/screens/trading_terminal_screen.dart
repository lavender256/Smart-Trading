import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/toolbar.dart';
import '../widgets/dom_panel.dart';
import '../widgets/watchlist.dart';
import '../widgets/stats_bar.dart';
import '../widgets/chart/chart_container.dart';

class TradingTerminalScreen extends ConsumerWidget {
  const TradingTerminalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider);
    final settings = ref.watch(settingsProvider);
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    final screenWidth = Responsive.width(context);
    final screenHeight = Responsive.height(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Toolbar
            const Toolbar(),

            // Loading indicator
            if (market.isLoading && market.candles.isEmpty)
              const LinearProgressIndicator(
                backgroundColor: AppColors.bgTertiary,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),

            // Error banner
            if (market.error != null)
              Container(
                height: 28,
                color: AppColors.danger.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Connection error: ${market.error}. Retrying...',
                        style: const TextStyle(color: AppColors.danger, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.wifi, color: AppColors.danger, size: 14),
                  ],
                ),
              ),

            // Main content
            Expanded(
              child: isMobile
                  ? _buildMobileLayout(context, ref, settings)
                  : isTablet
                      ? _buildTabletLayout(context, ref, settings, screenWidth)
                      : _buildDesktopLayout(context, ref, settings, screenWidth, screenHeight),
            ),

            // Stats bar
            const StatsBar(),
          ],
        ),
      ),
    );
  }

  /// Mobile: chart full width, panels stacked below
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, settings) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Chart (takes most of the screen)
          SizedBox(
            height: Responsive.height(context) * 0.5,
            child: const ChartContainer(),
          ),

          // DOM below chart
          if (settings.showDOM)
            SizedBox(
              height: 400,
              child: const DOMPanel(),
            ),

          // Watchlist
          const SizedBox(
            height: 250,
            child: Watchlist(),
          ),
        ],
      ),
    );
  }

  /// Tablet: chart + side panel (DOM + Watchlist stacked)
  Widget _buildTabletLayout(BuildContext context, WidgetRef ref, settings, double screenWidth) {
    final chartWidth = screenWidth * 0.6;
    final sideWidth = screenWidth * 0.4;

    return Row(
      children: [
        // Chart
        SizedBox(
          width: chartWidth,
          child: const ChartContainer(),
        ),
        // Side panels
        SizedBox(
          width: sideWidth,
          child: Column(
            children: [
              if (settings.showDOM)
                Expanded(
                  flex: 2,
                  child: const DOMPanel(),
                ),
              const Expanded(
                flex: 1,
                child: Watchlist(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Desktop: watchlist | chart | DOM
  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref, settings, double screenWidth, double screenHeight) {
    final watchlistWidth = Responsive.watchlistWidth(context);
    final domWidth = Responsive.domWidth(context);
    final chartWidth = screenWidth - watchlistWidth - domWidth;

    return Row(
      children: [
        // Left: Watchlist
        SizedBox(
          width: watchlistWidth,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: const Watchlist(),
          ),
        ),
        // Center: Chart
        Expanded(
          child: const ChartContainer(),
        ),
        // Right: DOM
        SizedBox(
          width: domWidth,
          child: const DOMPanel(),
        ),
      ],
    );
  }
}
