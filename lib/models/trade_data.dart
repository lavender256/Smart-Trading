class TradeData {
  final int id;
  final double price;
  final double quantity;
  final int timestamp;
  final bool isBuyerMaker;
  final bool isLarge;

  TradeData({
    required this.id,
    required this.price,
    required this.quantity,
    required this.timestamp,
    required this.isBuyerMaker,
    this.isLarge = false,
  });
}