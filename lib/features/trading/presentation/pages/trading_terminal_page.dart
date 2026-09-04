import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/utils/responsive.dart';
import '../bloc/market/market_bloc.dart';
import '../bloc/market/market_event.dart';
import '../bloc/market/market_state.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/settings/settings_state.dart';
import '../widgets/chart/chart_container.dart';
import '../widgets/dom_panel.dart';
import '../widgets/stats_bar.dart';
import '../widgets/toolbar.dart';
import '../widgets/watchlist.dart';

class TradingTerminalPage extends StatefulWidget {
  const TradingTerminalPage({super.key});

  @override
  State<TradingTerminalPage> createState() => _TradingTerminalPageState();
}

class _TradingTerminalPageState extends State<TradingTerminalPage> {
  @override
  void initState() {
    super.initState();
    // فقط هنگام ورود به این صفحه: قفل کردن گوشی در حالت افقی (Landscape)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // هنگام خروج از این صفحه: آزادسازی جهت چرخش گوشی به حالت‌های استاندارد
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final screenWidth = Responsive.width(context);
    final screenHeight = Responsive.height(context);

    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) =>
      previous.symbol != current.symbol || previous.interval != current.interval,
      listener: (context, settingsState) {
        context.read<MarketBloc>().add(
          MarketStartPolling(
            symbol: settingsState.symbol,
            interval: settingsState.interval,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // نوار ابزار اصلی
              const Toolbar(),

              // وضعیت لودینگ و خطاها
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
                    ],
                  );
                },
              ),

              // محتوای اصلی بر اساس لایوت
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

              // نوار آمار پایین صفحه
              const StatsBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// موبایل
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

  /// تبلت
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

  /// دسکتاپ
  Widget _buildDesktopLayout(BuildContext context, bool showDOM, double screenWidth, double screenHeight) {
    final watchlistWidth = Responsive.watchlistWidth(context);
    final domWidth = Responsive.domWidth(context);

    return Row(
      children: [
        SizedBox(
          width: watchlistWidth,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: const Watchlist(),
          ),
        ),
        const Expanded(
          child: ChartContainer(),
        ),
        if (showDOM)
          SizedBox(
            width: domWidth,
            child: const DOMPanel(),
          ),
      ],
    );
  }
}