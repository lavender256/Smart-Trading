import '../../../../../core/constants/chart_defaults.dart';

class SettingsState {
  final String symbol;
  final String interval;
  final bool showVolume;
  final bool showHeatmap;
  final bool showDOM;

  const SettingsState({
    this.symbol = ChartDefaults.defaultSymbol,
    this.interval = ChartDefaults.defaultInterval,
    this.showVolume = true,
    this.showHeatmap = true,
    this.showDOM = true,
  });

  SettingsState copyWith({
    String? symbol,
    String? interval,
    bool? showVolume,
    bool? showHeatmap,
    bool? showDOM,
  }) {
    return SettingsState(
      symbol: symbol ?? this.symbol,
      interval: interval ?? this.interval,
      showVolume: showVolume ?? this.showVolume,
      showHeatmap: showHeatmap ?? this.showHeatmap,
      showDOM: showDOM ?? this.showDOM,
    );
  }
}