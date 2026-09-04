class PriceLevel {
  final double price;
  final double quantity;

  const PriceLevel({required this.price, required this.quantity});
}

class DepthData {
  final List<PriceLevel> bids;
  final List<PriceLevel> asks;

  const DepthData({required this.bids, required this.asks});
}