import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/candle_data.dart';
import '../../domain/entities/depth_data.dart';

abstract class BinanceRemoteDataSource {
  Future<List<CandleData>> getKlines({
    required String symbol,
    required String interval,
    required int limit,
  });

  Future<DepthData> getDepth({
    required String symbol,
    required int limit,
  });
}

class BinanceRemoteDataSourceImpl implements BinanceRemoteDataSource {
  final http.Client client;

  BinanceRemoteDataSourceImpl({required this.client});

  static const String _baseUrl = 'https://api.binance.com/api/v3';

  // هدرهای مرورگر برای جلوگیری از بلاک شدن ریکوئست توسط بایننس
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json',
  };

  @override
  Future<List<CandleData>> getKlines({
    required String symbol,
    required String interval,
    required int limit,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/klines?symbol=${symbol.toUpperCase()}&interval=$interval&limit=$limit',
    );

    // پاس دادن هدرها به ریکوئست
    final response = await client.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) {
        return CandleData(
          openTime: item[0] as int,
          open: double.parse(item[1].toString()),
          high: double.parse(item[2].toString()),
          low: double.parse(item[3].toString()),
          close: double.parse(item[4].toString()),
          volume: double.parse(item[5].toString()),
          closeTime: item[6] as int,
          quoteVolume: double.parse(item[7].toString()),
          trades: item[8] as int,
          takerBuyBaseVol: double.parse(item[9].toString()),
          takerBuyQuoteVol: double.parse(item[10].toString()),
        );
      }).toList();
    } else {
      throw Exception('خطا در دریافت اطلاعات کندل‌ها از بایننس: ${response.statusCode}');
    }
  }

  @override
  Future<DepthData> getDepth({
    required String symbol,
    required int limit,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/depth?symbol=${symbol.toUpperCase()}&limit=$limit',
    );

    final response = await client.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      final bids = (data['bids'] as List).map((item) {
        return PriceLevel(
          price: double.parse(item[0].toString()),
          quantity: double.parse(item[1].toString()),
        );
      }).toList();

      final asks = (data['asks'] as List).map((item) {
        return PriceLevel(
          price: double.parse(item[0].toString()),
          quantity: double.parse(item[1].toString()),
        );
      }).toList();

      return DepthData(bids: bids, asks: asks);
    } else {
      throw Exception('خطا در دریافت اطلاعات عمق بازار: ${response.statusCode}');
    }
  }
}