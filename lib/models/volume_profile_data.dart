class VolumeProfileData {
  final List<VPLevel> levels;
  final double pocPrice;
  final double vahPrice;
  final double valPrice;
  final List<double> hvnPrices;
  final List<double> lvnPrices;
  final double totalVolume;

  VolumeProfileData({
    required this.levels,
    required this.pocPrice,
    required this.vahPrice,
    required this.valPrice,
    required this.hvnPrices,
    required this.lvnPrices,
    required this.totalVolume,
  });

  factory VolumeProfileData.empty() => VolumeProfileData(
        levels: [],
        pocPrice: 0,
        vahPrice: 0,
        valPrice: 0,
        hvnPrices: [],
        lvnPrices: [],
        totalVolume: 0,
      );
}

class VPLevel {
  final double priceLow;
  final double priceHigh;
  final double volume;
  final double buyVolume;
  final double sellVolume;
  final double pctOfTotal;

  VPLevel({
    required this.priceLow,
    required this.priceHigh,
    required this.volume,
    required this.buyVolume,
    required this.sellVolume,
    required this.pctOfTotal,
  });

  double get midPrice => (priceLow + priceHigh) / 2;
  double get buyPct => volume > 0 ? buyVolume / volume : 0;
  double get sellPct => volume > 0 ? sellVolume / volume : 0;
}
