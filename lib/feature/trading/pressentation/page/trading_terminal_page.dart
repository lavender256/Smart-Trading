// lib/features/trading/presentation/pages/trading_terminal_page.dart
import 'package:flutter/material.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/responsive.dart';
import '../widget/chart/chart_container.dart';
import '../widget/dom_panel.dart';
import '../widget/stats_bar.dart';
import '../widget/toolbar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widget/watchlist.dart';class TradingTerminalPage extends StatelessWidget {
  const TradingTerminalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final screenWidth = Responsive.width(context);
    final screenHeight = Responsive.height(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const Toolbar(),

            // گوش دادن به وضعیت مارکت
            BlocBuilder<MarketBloc, MarketState>(
              builder: (context, marketState) {
                return Column(
                    children: [
                      if (marketState.status == MarketStatus.loading && marketState.candles.isEmpty)
                        const LinearProgressIndicator(
                          backgroundColor: AppColors.bgTertiary,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),

                      if (marketState.status == MarketStatus.failure && marketState.error != null)
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
                                  'Connection error: ${marketState.error}. Retrying...',
                                  style: const TextStyle(color: AppColors.danger, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.wifi, color: AppColors.danger, size: 14),
                            ],
                          ),
                        ),
                    ];
                );
              },
            ),

            // محتوای اصلی (نمودار و پنل‌ها)
            Expanded(
              child: BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, settingsState) {
                  if (isMobile) {
                    return _buildMobileLayout(context, settingsState.showDOM);
                  } else if (isTablet) {
                    return _buildTabletLayout(context, settingsState.showDOM, screenWidth);
                  } else {
                    return _buildDesktopLayout(context, settingsState.showDOM, screenWidth, screenHeight);
                  }
                },
              ),
            ),

            const StatsBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool showDOM) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: Responsive.height(context) * 0.5,
            child: const ChartContainer(),
          ),
          if (showDOM)
            const SizedBox(
              height: 400,
              child: DOMPanel(),
            ),
          const SizedBox(
            height: 250,
            child: Watchlist(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, bool showDOM, double screenWidth) {
    final chartWidth = screenWidth * 0.6;
    final sideWidth = screenWidth * 0.4;

    return Row(
      children: [
        SizedBox(
          width: chartWidth,
          child: const ChartContainer(),
        ),
        SizedBox(
          width: sideWidth,
          child: Column(
            children: [
              if (showDOM)
                const Expanded(
                  flex: 2,
                  child: DOMPanel(),
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

  Widget _buildDesktopLayout(BuildContext context, bool showDOM, double screenWidth, double screenHeight) {
    final watchlistWidth = Responsive.watchlistWidth(context);
    final domWidth = Responsive.domWidth(context);

    return Row(
      children: [
        SizedBox(
          width: watchlistWidth,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: const Watchlist(),
          ),
        ),
        const Expanded(
          child: ChartContainer(),
        ),
        SizedBox(
          width: domWidth,
          child: const DOMPanel(),
        ),
      ],
    );
  }
}