import '../../../domain/entities/candle_data.dart';
import '../../../domain/entities/depth_data.dart';

enum MarketStatus { initial, loading, success, failure }

class MarketState {
  final MarketStatus status;
  final List<CandleData> candles;
  final DepthData? depth;
  final double cvd;
  final String? error;

  const MarketState({
    this.status = MarketStatus.initial,
    this.candles = const [],
    this.depth,
    this.cvd = 0.0,
    this.error,
  });

  MarketState copyWith({
    MarketStatus? status,
    List<CandleData>? candles,
    DepthData? depth,
    double? cvd,
    String? error,
  }) {
    return MarketState(
      status: status ?? this.status,
      candles: candles ?? this.candles,
      depth: depth ?? this.depth,
      cvd: cvd ?? this.cvd,
      error: error,
    );
  }
}