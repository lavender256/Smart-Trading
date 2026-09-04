class ChartDefaults {
  static const String defaultSymbol = 'BTCUSDT';
  static const String defaultInterval = '1h';

  static const int klineLimit = 500;
  static const int depthLimit = 100;
  static const int tradeLimit = 500;

  static const Duration klinePollInterval = Duration(seconds: 2);
  static const Duration depthPollInterval = Duration(milliseconds: 500);
  static const Duration vpPollInterval = Duration(seconds: 5);
  static const Duration heatmapPollInterval = Duration(seconds: 5);
  static const Duration tradePollInterval = Duration(seconds: 1);

  static const int heatmapTimeBins = 50;
  static const int heatmapPriceLevels = 50;
}