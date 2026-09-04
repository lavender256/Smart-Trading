import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/constants.dart';
import '../bloc/market/market_bloc.dart';
import '../bloc/market/market_state.dart';

class DOMPanel extends StatelessWidget {
  const DOMPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ORDER BOOK (DOM)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'PRICE / SIZE',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<MarketBloc, MarketState>(
              builder: (context, state) {
                final depth = state.depth;
                if (depth == null) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                  );
                }

                return Column(
                  children: [
                    // سفارشات فروش (Asks)
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: depth.asks.length > 15 ? 15 : depth.asks.length,
                        itemBuilder: (context, index) {
                          final ask = depth.asks[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ask.price.toStringAsFixed(2),
                                  style: const TextStyle(color: AppColors.danger, fontSize: 11),
                                ),
                                Text(
                                  ask.quantity.toStringAsFixed(3),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    // سفارشات خرید (Bids)
                    Expanded(
                      child: ListView.builder(
                        itemCount: depth.bids.length > 15 ? 15 : depth.bids.length,
                        itemBuilder: (context, index) {
                          final bid = depth.bids[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  bid.price.toStringAsFixed(2),
                                  style: const TextStyle(color: AppColors.success, fontSize: 11),
                                ),
                                Text(
                                  bid.quantity.toStringAsFixed(3),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}