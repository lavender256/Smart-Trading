import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/market_provider.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/responsive.dart';
import '../../domain/models/footprint_data.dart';


class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final height = Responsive.toolbarHeight(context);

    return Container(
      height: height,
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Symbol dropdown
            _buildSymbolDropdown(context, ref, settings),
            const SizedBox(width: 8),
            // Timeframe selector
            _buildTimeframeSelector(context, ref, settings),
            const SizedBox(width: 8),
            // Footprint mode dropdown
            if (settings.showVolume) ...[
              _buildFootprintSelector(context, ref, settings),
              const SizedBox(width: 8),
            ],
            // Layer toggles
            _buildLayerToggles(context, ref, settings),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolDropdown(BuildContext context, WidgetRef ref, dynamic settings) {
    final symbols = ['BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'XRPUSDT', 'DOGEUSDT'];
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: settings.symbol,
          dropdownColor: AppColors.bgTertiary,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          items: symbols.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) { if (v != null) ref.read(marketProvider.notifier).changeSymbol(v); },
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector(BuildContext context, WidgetRef ref, dynamic settings) {
    final intervals = ['1m', '5m', '15m', '1h', '4h', '1d'];
    return Row(
      children: intervals.map((tf) {
        final isActive = settings.interval == tf;
        return GestureDetector(
          onTap: () => ref.read(marketProvider.notifier).changeInterval(tf),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: isActive ? AppColors.active : AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isActive ? AppColors.active : AppColors.border),
            ),
            child: Center(child: Text(tf, style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary, fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFootprintSelector(BuildContext context, WidgetRef ref, dynamic settings) {
    final modes = {
      FootprintMode.bidAsk: 'Bid|Ask',
      FootprintMode.bidXAsk: 'Bid×Ask',
      FootprintMode.delta: 'Delta',
      FootprintMode.volume: 'Volume',
      FootprintMode.imbalance: 'Imbalance',
    };
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FootprintMode>(
          value: settings.footprintMode,
          dropdownColor: AppColors.bgTertiary,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
          items: modes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 11)))).toList(),
          onChanged: (v) { if (v != null) ref.read(settingsProvider.notifier).setFootprintMode(v); },
        ),
      ),
    );
  }

  Widget _buildLayerToggles(BuildContext context, WidgetRef ref, dynamic settings) {
    final layers = [
      ('Volume', 'volume', Icons.bar_chart, settings.showVolume),
      ('Heatmap', 'heatmap', Icons.grid_on, settings.showHeatmap),
      ('Walls', 'walls', Icons.shield, settings.showLiquidityWalls),
      ('Imbalance', 'imbalance', Icons.warning_amber, settings.showImbalance),
      ('VP', 'vp', Icons.equalizer, settings.showVP),
      ('CVD', 'cvd', Icons.show_chart, settings.showCVD),
      ('DOM', 'dom', Icons.view_list, settings.showDOM),
      ('Trades', 'largeTrades', Icons.bolt, settings.showLargeTrades),
    ];

    return Row(
      children: layers.map((l) {
        final String title = l.$1 as String;
        final String layerKey = l.$2 as String;
        final IconData icon = l.$3 as IconData;
        final bool active = l.$4 as bool; // این خط مشکل Undefined name 'active' رو حل می‌کنه

        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Tooltip(
            message: title,
            child: GestureDetector(
              onTap: () => ref.read(settingsProvider.notifier).toggleLayer(layerKey),
              child: Container(
                height: 28,
                width: 32,
                decoration: BoxDecoration(
                  color: active ? AppColors.active.withOpacity(0.3) : AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: active ? AppColors.active : AppColors.border),
                ),
                child: Icon(icon, size: 16, color: active ? AppColors.active : AppColors.textMuted),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}