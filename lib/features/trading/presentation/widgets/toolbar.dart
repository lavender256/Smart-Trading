import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/constants.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/settings/settings_event.dart';
import '../bloc/settings/settings_state.dart';

class Toolbar extends StatelessWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return Row(
            children: [
              // انتخاب جفت‌ارز
              DropdownButton<String>(
                value: settingsState.symbol,
                dropdownColor: AppColors.bgSecondary,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'BTCUSDT', child: Text('BTC/USDT')),
                  DropdownMenuItem(value: 'ETHUSDT', child: Text('ETH/USDT')),
                  DropdownMenuItem(value: 'SOLUSDT', child: Text('SOL/USDT')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    context.read<SettingsBloc>().add(SettingsSymbolChanged(value));
                  }
                },
              ),

              const SizedBox(width: 16),
              const VerticalDivider(color: AppColors.border, indent: 8, endIndent: 8),
              const SizedBox(width: 16),

              // انتخاب تایم‌فریم
              ...['1m', '5m', '15m', '1h', '4h', '1d'].map((tf) {
                final isSelected = settingsState.interval == tf;
                return InkWell(
                  onTap: () {
                    context.read<SettingsBloc>().add(SettingsIntervalChanged(tf));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tf,
                      style: TextStyle(
                        color: isSelected ? AppColors.accent : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),

              const Spacer(),

              // سوئیچ نمایش DOM
              IconButton(
                icon: Icon(
                  Icons.view_sidebar_outlined,
                  color: settingsState.showDOM ? AppColors.accent : AppColors.textSecondary,
                  size: 18,
                ),
                onPressed: () {
                  context.read<SettingsBloc>().add(SettingsLayerToggled('dom'));
                },
              ),
            ],
          );
        },
      ),
    );
  }
}