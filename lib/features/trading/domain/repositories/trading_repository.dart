import '../entities/candle_data.dart';
import '../entities/depth_data.dart';

abstract class TradingRepository {
  Future<List<CandleData>> getKlines({
    required String symbol,
    required String interval,
    int limit = 500,
  });

  Future<DepthData> getDepth({
    required String symbol,
    int limit = 100,
  });
}