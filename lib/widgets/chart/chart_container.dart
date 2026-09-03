import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/footprint_data.dart';
import '../../providers/market_provider.dart';
import '../../utils/constants.dart';
import 'chart_engine.dart';

class ChartContainer extends ConsumerStatefulWidget {
  const ChartContainer({super.key});

  @override
  ConsumerState<ChartContainer> createState() => _ChartContainerState();
}

class _ChartContainerState extends ConsumerState<ChartContainer> {
  int _visibleStart = 0;
  int _visibleCount = AppDimensions.baseVisibleCandles.toInt();
  Offset? _crosshairPos;

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final settings = ref.watch(settingsProvider);

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          final dx = details.delta.dx;
          final candleShift = (dx / 10).round();
          final newStart = (_visibleStart - candleShift).clamp(
            0,
            (market.candles.length - _visibleCount).clamp(0, 99999),
          );
          _visibleStart = newStart;
        });
      },
      onScaleUpdate: (details) {
        if (details.scale != 1.0) {
          setState(() {
            final oldCount = _visibleCount;
            final newCount = (oldCount / details.scale).round().clamp(
              10,
              AppDimensions.maxCandleWidth.toInt() * 10,
            );
            // Adjust start to keep center
            final centerIdx = _visibleStart + oldCount ~/ 2;
            _visibleCount = newCount;
            _visibleStart = (centerIdx - newCount ~/ 2).clamp(
              0,
              (market.candles.length - _visibleCount).clamp(0, 99999),
            );
          });
        }
      },
      onHorizontalDragEnd: (_) {},
      onScaleEnd: (_) {},
      child: MouseRegion(
        onHover: (event) {
          if (settings.showCrosshair) {
            setState(() {
              _crosshairPos = event.localPosition;
            });
          }
        },
        onExit: (event) {
          setState(() {
            _crosshairPos = null;
          });
        },
        child: Container(
          color: AppColors.bgPrimary,
          child: CustomPaint(
            size: Size.infinite,
            painter: ChartEngine(
              candles: market.candles,
              volumeProfile: market.volumeProfile,
              footprints: market.footprints,
              heatmap: market.heatmap,
              liquidityWalls: market.liquidityWalls,
              largeTrades: market.largeTrades,
              cvd: market.cvd,
              footprintMode: settings.footprintMode,
              showVolume: settings.showVolume,
              showHeatmap: settings.showHeatmap,
              showLiquidityWalls: settings.showLiquidityWalls,
              showImbalance: settings.showImbalance,
              showVP: settings.showVP,
              showCVD: settings.showCVD,
              showLargeTrades: settings.showLargeTrades,
              showCrosshair: settings.showCrosshair,
              visibleStart: _visibleStart,
              visibleCount: _visibleCount,
              crosshairPos: _crosshairPos,
            ),
          ),
        ),
      ),
    );
  }
}
