import 'package:dio/dio.dart';

import '../feature/trading/domain/models/candle_data.dart';
import '../feature/trading/domain/models/depth_data.dart';
import '../feature/trading/domain/models/footprint_data.dart';
import '../feature/trading/domain/models/liquidity_data.dart';
import '../feature/trading/domain/models/trade_data.dart';
import '../feature/trading/domain/models/volume_profile_data.dart';


class BinanceService {
  static const String baseUrl = 'https://api.binance.com';
  final Dio _dio;

  BinanceService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  // Fetch klines (candlestick data)
  Future<List<CandleData>> getKlines({
    required String symbol,
    String interval = '1m',
    int limit = 200,
  }) async {
    try {
      final response = await _dio.get('/api/v3/klines', queryParameters: {
        'symbol': symbol,
        'interval': interval,
        'limit': limit,
      });
      final List<dynamic> data = response.data;
      return data
          .map((e) => CandleData.fromBinance(e as List<dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch klines: $e');
    }
  }

  // Fetch order book depth
  Future<DepthData> getDepth({
    required String symbol,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get('/api/v3/depth', queryParameters: {
        'symbol': symbol,
        'limit': limit,
      });
      return DepthData.fromBinance(response.data);
    } catch (e) {
      throw Exception('Failed to fetch depth: $e');
    }
  }

  // Fetch recent trades for footprint
  Future<List<TradeData>> getTrades({
    required String symbol,
    int limit = 500,
    int? startTime,
  }) async {
    try {
      final params = <String, dynamic>{
        'symbol': symbol,
        'limit': limit,
      };
      if (startTime != null && startTime > 0) {
        params['startTime'] = startTime;
      }
      final response =
          await _dio.get('/api/v3/aggTrades', queryParameters: params);
      final List<dynamic> data = response.data;
      return data
          .map((e) => TradeData(
                id: e['a'] as int,
                price: double.parse(e['p'].toString()),
                quantity: double.parse(e['q'].toString()),
                timestamp: e['T'] as int,
                isBuyerMaker: e['m'] as bool,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch trades: $e');
    }
  }

  // Compute volume profile from candles
  VolumeProfileData computeVolumeProfile(List<CandleData> candles) {
    if (candles.isEmpty) return VolumeProfileData.empty();

    double lowest =
        candles.fold(999999999.0, (min, c) => c.low < min ? c.low : min);
    double highest = candles.fold(0.0, (max, c) => c.high > max ? c.high : max);
    final range = highest - lowest;
    if (range <= 0) return VolumeProfileData.empty();

    const int numBins = 100;
    final double binSize = range / numBins;

    final bins = List<Map<String, double>>.generate(numBins, (_) => {
          'volume': 0.0,
          'buyVolume': 0.0,
          'sellVolume': 0.0,
        });

    for (final candle in candles) {
      final candleRange = candle.high - candle.low;
      if (candleRange <= 0) continue;

      for (int i = 0; i < numBins; i++) {
        final binLow = lowest + i * binSize;
        final binHigh = binLow + binSize;
        final overlap = _computeOverlap(
          binLow: binLow,
          binHigh: binHigh,
          candleLow: candle.low,
          candleHigh: candle.high,
        );
        if (overlap <= 0) continue;

        final fraction = overlap / candleRange;
        bins[i]['volume'] = bins[i]['volume']! + candle.volume * fraction;
        bins[i]['buyVolume'] =
            bins[i]['buyVolume']! + candle.takerBuyBaseVol * fraction;
        bins[i]['sellVolume'] =
            bins[i]['sellVolume']! + candle.sellVolume * fraction;
      }
    }

    double totalVolume = bins.fold(0.0, (s, b) => s + b['volume']!);
    if (totalVolume <= 0) return VolumeProfileData.empty();

    // Build levels, excluding empty
    final levels = <VPLevel>[];
    for (int i = 0; i < numBins; i++) {
      final vol = bins[i]['volume']!;
      if (vol <= 0) continue;
      levels.add(VPLevel(
        priceLow: lowest + i * binSize,
        priceHigh: lowest + (i + 1) * binSize,
        volume: vol,
        buyVolume: bins[i]['buyVolume']!,
        sellVolume: bins[i]['sellVolume']!,
        pctOfTotal: vol / totalVolume,
      ));
    }
    levels.sort((a, b) => b.volume.compareTo(a.volume));

    // POC = highest volume
    final poc = levels.isNotEmpty ? levels.first.midPrice : 0.0;

    // VAH/VAL (70% value area)
    double targetVol = totalVolume * 0.70;
    double accumulated = 0;
    double vah = levels.isNotEmpty ? levels.first.priceHigh : 0.0;
    double val = levels.isNotEmpty ? levels.last.priceLow : 0.0;
    bool foundTop = false;
    bool foundBottom = false;

    for (final level in levels) {
      accumulated += level.volume;
      if (!foundTop) {
        vah = level.priceHigh;
      }
      if (!foundBottom) {
        val = level.priceLow;
      }
      if (accumulated >= targetVol) {
        if (!foundTop) foundTop = true;
        else if (!foundBottom) foundBottom = true;
        if (foundTop && foundBottom) break;
      }
    }

    // HVN/LVN
    final avgVol = levels.isNotEmpty ? totalVolume / levels.length : 0;
    final hvn = levels
        .where((l) => l.volume >= avgVol * 2.0)
        .map((l) => l.midPrice)
        .toList();
    final lvn = levels
        .where((l) => l.volume <= avgVol * 0.3 && l.volume > 0)
        .map((l) => l.midPrice)
        .toList();

    return VolumeProfileData(
      levels: levels,
      pocPrice: poc,
      vahPrice: vah,
      valPrice: val,
      hvnPrices: hvn,
      lvnPrices: lvn,
      totalVolume: totalVolume,
    );
  }

  double _computeOverlap({
    required double binLow,
    required double binHigh,
    required double candleLow,
    required double candleHigh,
  }) {
    final overlapLow = binLow > candleLow ? binLow : candleLow;
    final overlapHigh = binHigh < candleHigh ? binHigh : candleHigh;
    return overlapHigh > overlapLow ? overlapHigh - overlapLow : 0.0;
  }

  // Build footprint data from trades
  List<FootprintCandle> buildFootprint(
      List<TradeData> trades, List<CandleData> candles) {
    if (trades.isEmpty || candles.isEmpty) return [];

    // Group trades into candle time windows
    final Map<int, List<TradeData>> grouped = {};
    for (final trade in trades) {
      // Find the candle this trade belongs to
      for (int i = candles.length - 1; i >= 0; i--) {
        final candle = candles[i];
        if (trade.timestamp >= candle.openTime &&
            trade.timestamp < candle.openTime + 60000) {
          grouped.putIfAbsent(i, () => []).add(trade);
          break;
        }
      }
    }

    final result = <FootprintCandle>[];
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final candleTrades = grouped[i] ?? [];
      if (candleTrades.isEmpty) continue;

      // Group by price levels
      final priceStep = _calcPriceStep(candle);
      if (priceStep <= 0) continue;

      final priceMap = <double, FootprintLevel>{};
      for (final trade in candleTrades) {
        final levelPrice = (trade.price / priceStep).floor() * priceStep;
        final existing = priceMap[levelPrice];
        final buyQty = trade.isBuyerMaker ? 0.0 : trade.quantity;
        final sellQty = trade.isBuyerMaker ? trade.quantity : 0.0;

        if (existing != null) {
          priceMap[levelPrice] = FootprintLevel(
            price: levelPrice,
            buyVolume: existing.buyVolume + buyQty,
            sellVolume: existing.sellVolume + sellQty,
            delta: existing.delta + buyQty - sellQty,
            totalVolume: existing.totalVolume + trade.quantity,
            isImbalance: false,
          );
        } else {
          priceMap[levelPrice] = FootprintLevel(
            price: levelPrice,
            buyVolume: buyQty,
            sellVolume: sellQty,
            delta: buyQty - sellQty,
            totalVolume: trade.quantity,
            isImbalance: false,
          );
        }
      }

      // Sort by price descending and detect imbalances
      var levels = priceMap.values.toList()
        ..sort((a, b) => b.price.compareTo(a.price));

      // Imbalance detection: buy > sell * 3 or sell > buy * 3
      for (final level in levels) {
        if (level.buyVolume > 0 && level.sellVolume > 0) {
          final ratio = level.buyVolume > level.sellVolume
              ? level.buyVolume / level.sellVolume
              : level.sellVolume / level.buyVolume;
          if (ratio >= 3.0) {
            priceMap[level.price] = FootprintLevel(
              price: level.price,
              buyVolume: level.buyVolume,
              sellVolume: level.sellVolume,
              delta: level.delta,
              totalVolume: level.totalVolume,
              isImbalance: true,
              imbalanceRatio: ratio,
            );
          }
        }
      }

      levels = priceMap.values.toList()
        ..sort((a, b) => b.price.compareTo(a.price));

      double totalBuy = 0, totalSell = 0;
      for (final l in levels) {
        totalBuy += l.buyVolume;
        totalSell += l.sellVolume;
      }

      result.add(FootprintCandle(
        openTime: candle.openTime,
        levels: levels,
        open: candle.open,
        high: candle.high,
        low: candle.low,
        close: candle.close,
        totalBuyVolume: totalBuy,
        totalSellVolume: totalSell,
        totalDelta: totalBuy - totalSell,
        isBullish: candle.isBullish,
      ));
    }
    return result;
  }

  double _calcPriceStep(CandleData candle) {
    final range = candle.high - candle.low;
    if (range <= 0) return 0;
    if (range < 0.5) return 0.01;
    if (range < 5) return 0.1;
    if (range < 50) return 1.0;
    if (range < 500) return 10.0;
    return 100.0;
  }

  // Generate heatmap data
  List<HeatmapPoint> generateHeatmap({
    required List<CandleData> candles,
    required DepthData? depth,
    int timeBins = 20,
    int priceLevels = 30,
  }) {
    if (candles.isEmpty) return [];

    double lowest =
        candles.fold(999999999.0, (min, c) => c.low < min ? c.low : min);
    double highest = candles.fold(0.0, (max, c) => c.high > max ? c.high : max);
    final range = highest - lowest;
    if (range <= 0) return [];

    final priceStep = range / priceLevels;
    final candleStep = (candles.length / timeBins).ceil();
    final avgVolume =
        candles.fold(0.0, (s, c) => s + c.volume) / candles.length;

    final points = <HeatmapPoint>[];

    for (int t = 0; t < timeBins && t * candleStep < candles.length; t++) {
      final startIdx = t * candleStep;
      final endIdx = (startIdx + candleStep).clamp(0, candles.length);
      for (int p = 0; p < priceLevels; p++) {
        final pLow = lowest + p * priceStep;
        final pHigh = pLow + priceStep;

        double bidIntensity = 0;
        double askIntensity = 0;

        for (int i = startIdx; i < endIdx; i++) {
          final c = candles[i];
          final overlap = _computeOverlap(
            binLow: pLow,
            binHigh: pHigh,
            candleLow: c.low,
            candleHigh: c.high,
          );
          if (overlap <= 0) continue;
          final frac = overlap / (c.range > 0 ? c.range : 1);
          bidIntensity += c.takerBuyBaseVol * frac;
          askIntensity += c.sellVolume * frac;
        }

        points.add(HeatmapPoint(
          timeBin: t,
          priceLevel: p.toDouble(),
          bidIntensity: bidIntensity / (avgVolume > 0 ? avgVolume : 1),
          askIntensity: askIntensity / (avgVolume > 0 ? avgVolume : 1),
          totalIntensity:
              (bidIntensity + askIntensity) / (avgVolume > 0 ? avgVolume : 1),
        ));
      }
    }

    return points;
  }

  // Detect liquidity walls from depth
  List<LiquidityWall> detectLiquidityWalls(DepthData depth) {
    final walls = <LiquidityWall>[];

    // Bid walls
    if (depth.bids.isNotEmpty) {
      final avgBidQty = depth.totalBidVolume / depth.bids.length;
      for (final level in depth.bids) {
        if (level.quantity >= avgBidQty * 3) {
          walls.add(LiquidityWall(
            price: level.price,
            quantity: level.quantity,
            side: 'bid',
            avgQuantity: avgBidQty,
            strength: level.quantity / (avgBidQty > 0 ? avgBidQty : 1),
          ));
        }
      }
    }

    // Ask walls
    if (depth.asks.isNotEmpty) {
      final avgAskQty = depth.totalAskVolume / depth.asks.length;
      for (final level in depth.asks) {
        if (level.quantity >= avgAskQty * 3) {
          walls.add(LiquidityWall(
            price: level.price,
            quantity: level.quantity,
            side: 'ask',
            avgQuantity: avgAskQty,
            strength: level.quantity / (avgAskQty > 0 ? avgAskQty : 1),
          ));
        }
      }
    }

    walls.sort((a, b) => b.strength.compareTo(a.strength));
    return walls;
  }
}
