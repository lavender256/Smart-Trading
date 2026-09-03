class CandleData {
  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final double quoteVolume;
  final int trades;
  final double takerBuyBaseVol;
  final double takerBuyQuoteVol;
  final bool isBullish;

  CandleData({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.quoteVolume,
    required this.trades,
    required this.takerBuyBaseVol,
    required this.takerBuyQuoteVol,
    bool? isBullish,
  }) : isBullish = isBullish ?? (close >= open);

  double get bodyTop => isBullish ? close : open;
  double get bodyBottom => isBullish ? open : close;
  double get bodySize => (bodyTop - bodyBottom).abs();
  double get wickTop => high - bodyTop;
  double get wickBottom => bodyBottom - low;
  double get midPrice => (high + low) / 2;
  double get range => high - low;
  double get sellVolume => volume - takerBuyBaseVol;

  factory CandleData.fromBinance(List<dynamic> raw) {
    return CandleData(
      openTime: raw[0] as int,
      open: double.parse(raw[1].toString()),
      high: double.parse(raw[2].toString()),
      low: double.parse(raw[3].toString()),
      close: double.parse(raw[4].toString()),
      volume: double.parse(raw[5].toString()),
      quoteVolume: double.parse(raw[7].toString()),
      trades: raw[8] as int,
      takerBuyBaseVol: double.parse(raw[9].toString()),
      takerBuyQuoteVol: double.parse(raw[10].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'openTime': openTime,
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': volume,
        'quoteVolume': quoteVolume,
        'trades': trades,
        'takerBuyBaseVol': takerBuyBaseVol,
        'takerBuyQuoteVol': takerBuyQuoteVol,
      };
}
