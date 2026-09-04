import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/constants.dart';
import '../bloc/market/market_bloc.dart';
import '../bloc/market/market_state.dart';

class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BlocBuilder<MarketBloc, MarketState>(
        builder: (context, state) {
          final lastCandle = state.candles.isNotEmpty ? state.candles.last : null;
          final price = lastCandle?.close ?? 0.0;

          return Row(
            children: [
              Text(
                'Price: ${price.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
              ),
              const SizedBox(width: 16),
              Text(
                'CVD: ${state.cvd.toStringAsFixed(2)}',
                style: TextStyle(
                  color: state.cvd >= 0 ? AppColors.success : AppColors.danger,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.status == MarketStatus.success ? AppColors.success : AppColors.danger,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                state.status == MarketStatus.success ? 'CONNECTED' : 'DISCONNECTED',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
              ),
            ],
          );
        },
      ),
    );
  }
}