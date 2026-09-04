import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/constants.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/settings/settings_event.dart';
import '../bloc/settings/settings_state.dart';

class Watchlist extends StatelessWidget {
  const Watchlist({super.key});

  static const List<Map<String, String>> _symbols = [
    {'symbol': 'BTCUSDT', 'name': 'Bitcoin'},
    {'symbol': 'ETHUSDT', 'name': 'Ethereum'},
    {'symbol': 'SOLUSDT', 'name': 'Solana'},
    {'symbol': 'BNBUSDT', 'name': 'BNB'},
    {'symbol': 'XRPUSDT', 'name': 'XRP'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Text(
              'WATCHLIST',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) {
                return ListView.builder(
                  itemCount: _symbols.length,
                  itemBuilder: (context, index) {
                    final item = _symbols[index];
                    final isSelected = settingsState.symbol == item['symbol'];

                    return InkWell(
                      onTap: () {
                        context.read<SettingsBloc>().add(
                          SettingsSymbolChanged(item['symbol']!),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        color: isSelected ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
                        child: Row(
                          mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['symbol']!,
                              style: TextStyle(
                                color: isSelected ? AppColors.accent : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              item['name']!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}