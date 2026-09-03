import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/market_provider.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/format_utils.dart';


class StatsBar extends ConsumerWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider);
    final settings = ref.watch(settingsProvider);
    final candles = market.candles;
    final depth = market.depth;

    String price = '--';
    String change = '--';
    String high = '--';
    String low = '--';
    String volume = '--';
    String trades = '--';
    String bidAsk = '--';
    String cvd = '--';

    if (candles.isNotEmpty) {
      final last = candles.last;
      price = FormatUtils.formatPrice(last.close);
      if (candles.length > 1) {
        final first = candles.first;
        final pct = ((last.close - first.open) / first.open) * 100;
        change = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%';
      }
      high = FormatUtils.formatPrice(candles.fold(0.0, (m, c) => c.high > m ? c.high : m));
      low = FormatUtils.formatPrice(candles.fold(999999.0, (m, c) => c.low < m ? c.low : m));
      volume = FormatUtils.formatVolume(candles.fold(0.0, (s, c) => s + c.volume), compact: true);
      trades = FormatUtils.formatNumber(candles.fold<int>(0, (s, c) => s + c.trades));
    }

    if (depth != null) {
      bidAsk = '${depth.bidAskRatio.toStringAsFixed(2)}';
    }

    cvd = FormatUtils.formatDelta(market.cvd);

    return Container(
      height: AppDimensions.statsBarHeight,
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _stat('Price', price, AppColors.currentPrice),
            _stat('Change', change, candles.isNotEmpty && candles.last.close >= candles.first.open ? AppColors.bull : AppColors.bear),
            _stat('High', high, AppColors.bull),
            _stat('Low', low, AppColors.bear),
            _stat('Volume', volume, AppColors.textPrimary),
            _stat('Trades', trades, AppColors.textPrimary),
            _stat('B/A Ratio', bidAsk, AppColors.accent),
            _stat('CVD', cvd, market.cvd >= 0 ? AppColors.cvdPositive : AppColors.cvdNegative),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
