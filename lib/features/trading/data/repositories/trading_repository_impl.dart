import '../../domain/entities/candle_data.dart';
import '../../domain/entities/depth_data.dart';
import '../../domain/repositories/trading_repository.dart';
import '../datasources/binance_remote_datasource.dart';

class TradingRepositoryImpl implements TradingRepository {
  final BinanceRemoteDataSource remoteDataSource;

  TradingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CandleData>> getKlines({
    required String symbol,
    required String interval,
    int limit = 500,
  }) async {
    return await remoteDataSource.getKlines(
      symbol: symbol,
      interval: interval,
      limit: limit,
    );
  }

  @override
  Future<DepthData> getDepth({
    required String symbol,
    int limit = 100,
  }) async {
    return await remoteDataSource.getDepth(
      symbol: symbol,
      limit: limit,
    );
  }
}