class CandleData {
  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final int closeTime;
  final double quoteVolume;
  final int trades;
  final double takerBuyBaseVol;
  final double takerBuyQuoteVol;

  const CandleData({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.closeTime,
    required this.quoteVolume,
    required this.trades,
    required this.takerBuyBaseVol,
    required this.takerBuyQuoteVol,
  });

  double get sellVolume => volume - takerBuyBaseVol;
}