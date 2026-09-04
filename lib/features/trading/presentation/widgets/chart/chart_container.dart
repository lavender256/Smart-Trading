import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/constants.dart';
import '../../bloc/market/market_bloc.dart';
import '../../bloc/market/market_state.dart';

class ChartContainer extends StatelessWidget {
  const ChartContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      width: double.infinity,
      height: double.infinity,
      child: BlocBuilder<MarketBloc, MarketState>(
        builder: (context, state) {
          if (state.status == MarketStatus.loading && state.candles.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (state.candles.isEmpty) {
            return const Center(
              child: Text(
                'No candle data available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.show_chart, size: 48, color: AppColors.accent),
                const SizedBox(height: 12),
                Text(
                  'Candles Loaded: ${state.candles.length}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Latest Close: \$${state.candles.last.close.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.success, fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}