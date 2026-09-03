enum FootprintMode { bidAsk, bidXAsk, delta, volume, imbalance }

class FootprintLevel {
  final double price;
  final double buyVolume;
  final double sellVolume;
  final double delta;
  final double totalVolume;
  final bool isImbalance;
  final double imbalanceRatio;

  FootprintLevel({
    required this.price,
    required this.buyVolume,
    required this.sellVolume,
    required this.delta,
    required this.totalVolume,
    this.isImbalance = false,
    this.imbalanceRatio = 0,
  });
}

class FootprintCandle {
  final int openTime;
  final List<FootprintLevel> levels;
  final double open;
  final double high;
  final double low;
  final double close;
  final double totalBuyVolume;
  final double totalSellVolume;
  final double totalDelta;
  final bool isBullish;

  FootprintCandle({
    required this.openTime,
    required this.levels,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.totalBuyVolume,
    required this.totalSellVolume,
    required this.totalDelta,
    this.isBullish = true,
  });
}
