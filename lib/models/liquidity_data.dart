class HeatmapPoint {
  final int timeBin;
  final double priceLevel;
  final double bidIntensity;
  final double askIntensity;
  final double totalIntensity;

  HeatmapPoint({
    required this.timeBin,
    required this.priceLevel,
    required this.bidIntensity,
    required this.askIntensity,
    required this.totalIntensity,
  });
}

class LiquidityWall {
  final double price;
  final double quantity;
  final String side; // 'bid' or 'ask'
  final double avgQuantity;
  final double strength;

  LiquidityWall({
    required this.price,
    required this.quantity,
    required this.side,
    required this.avgQuantity,
    required this.strength,
  });
}

class LiquidityEvent {
  final String type; // 'pull', 'add', 'absorption'
  final double price;
  final double quantity;
  final String side;
  final DateTime timestamp;

  LiquidityEvent({
    required this.type,
    required this.price,
    required this.quantity,
    required this.side,
    required this.timestamp,
  });
}
