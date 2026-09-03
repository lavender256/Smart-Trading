class DepthData {
  final List<DepthLevel> bids;
  final List<DepthLevel> asks;
  final double spread;
  final double midPrice;
  final DateTime timestamp;

  DepthData({
    required this.bids,
    required this.asks,
    required this.spread,
    required this.midPrice,
    required this.timestamp,
  });

  double get totalBidVolume => bids.fold(0.0, (s, l) => s + l.quantity);
  double get totalAskVolume => asks.fold(0.0, (s, l) => s + l.quantity);
  double get bidAskRatio => totalAskVolume > 0 ? totalBidVolume / totalAskVolume : 1.0;

  factory DepthData.fromBinance(Map<String, dynamic> json) {
    final rawBids = json['bids'] as List;
    final rawAsks = json['asks'] as List;
    final bids = rawBids
        .map((e) => DepthLevel(
              price: double.parse(e[0].toString()),
              quantity: double.parse(e[1].toString()),
            ))
        .toList();
    final asks = rawAsks
        .map((e) => DepthLevel(
              price: double.parse(e[0].toString()),
              quantity: double.parse(e[1].toString()),
            ))
        .toList();
    bids.sort((a, b) => b.price.compareTo(a.price));
    asks.sort((a, b) => a.price.compareTo(b.price));
    final bestBid = bids.isNotEmpty ? bids.first.price : 0.0;
    final bestAsk = asks.isNotEmpty ? asks.first.price : 0.0;
    return DepthData(
      bids: bids,
      asks: asks,
      spread: bestAsk - bestBid,
      midPrice: (bestBid + bestAsk) / 2,
      timestamp: DateTime.now(),
    );
  }
}

class DepthLevel {
  final double price;
  final double quantity;

  DepthLevel({required this.price, required this.quantity});
}
