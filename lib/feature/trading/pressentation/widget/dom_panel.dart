import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/market_provider.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/format_utils.dart';
import '../../domain/models/depth_data.dart';


class DOMPanel extends ConsumerWidget {
  const DOMPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(marketProvider);
    final depth = market.depth;
    final settings = ref.watch(settingsProvider);

    if (!settings.showDOM || depth == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: AppColors.bgTertiary,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Price', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('Size', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('Total', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Asks (reversed — lowest ask at bottom)
          ...depth.asks.take(15).toList().reversed.map((level) => _buildLevel(
            context, level.price, level.quantity, isBid: false,
          )),
          // Spread
          _buildSpread(depth),
          // Bids
          ...depth.bids.take(15).map((level) => _buildLevel(
            context, level.price, level.quantity, isBid: true,
          )),
        ],
      ),
    );
  }

  Widget _buildLevel(BuildContext context, double price, double qty, {required bool isBid}) {
    final decimals = FormatUtils.priceDecimals(price);
    return Container(
      height: AppDimensions.domLevelHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isBid ? AppColors.domBidBg : AppColors.domAskBg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(FormatUtils.formatPrice(price), style: TextStyle(
            color: isBid ? AppColors.bull : AppColors.bear,
            fontSize: 11,
            fontFamily: 'monospace',
          )),
          Text(FormatUtils.formatVolume(qty, compact: true), style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 11, fontFamily: 'monospace',
          )),
          SizedBox(
            width: 60,
            child: Stack(
              children: [
                const SizedBox.expand(),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: qty.clamp(0, 1), // Will be normalized in real use
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBid ? AppColors.bull.withOpacity(0.3) : AppColors.bear.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpread(DepthData depth) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.bgSecondary,
      child: Center(
        child: Text(
          'Spread: ${FormatUtils.formatSpread(depth.spread, depth.midPrice)}',
          style: const TextStyle(color: AppColors.warning, fontSize: 10),
        ),
      ),
    );
  }
}
