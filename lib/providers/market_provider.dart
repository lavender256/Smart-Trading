import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feature/trading/domain/models/candle_data.dart';
import '../feature/trading/domain/models/depth_data.dart';
import '../feature/trading/domain/models/footprint_data.dart';
import '../feature/trading/domain/models/liquidity_data.dart';
import '../feature/trading/domain/models/trade_data.dart';
import '../feature/trading/domain/models/volume_profile_data.dart';
import '../services/binance_service.dart';
import '../utils/constants.dart';

// ─── Settings State ───────────────────────────────────────────────

class SettingsState {
  final String symbol;
  final String interval;
  final FootprintMode footprintMode;
  final bool showVolume;
  final bool showHeatmap;
  final bool showLiquidityWalls;
  final bool showImbalance;
  final bool showVP;
  final bool showCVD;
  final bool showDOM;
  final bool showLargeTrades;
  final bool showCrosshair;

  const SettingsState({
    this.symbol = ChartDefaults.defaultSymbol,
    this.interval = ChartDefaults.defaultInterval,
    this.footprintMode = FootprintMode.bidAsk,
    this.showVolume = true,
    this.showHeatmap = true,
    this.showLiquidityWalls = true,
    this.showImbalance = true,
    this.showVP = true,
    this.showCVD = true,
    this.showDOM = true,
    this.showLargeTrades = true,
    this.showCrosshair = true,
  });

  SettingsState copyWith({
    String? symbol,
    String? interval,
    FootprintMode? footprintMode,
    bool? showVolume,
    bool? showHeatmap,
    bool? showLiquidityWalls,
    bool? showImbalance,
    bool? showVP,
    bool? showCVD,
    bool? showDOM,
    bool? showLargeTrades,
    bool? showCrosshair,
  }) {
    return SettingsState(
      symbol: symbol ?? this.symbol,
      interval: interval ?? this.interval,
      footprintMode: footprintMode ?? this.footprintMode,
      showVolume: showVolume ?? this.showVolume,
      showHeatmap: showHeatmap ?? this.showHeatmap,
      showLiquidityWalls: showLiquidityWalls ?? this.showLiquidityWalls,
      showImbalance: showImbalance ?? this.showImbalance,
      showVP: showVP ?? this.showVP,
      showCVD: showCVD ?? this.showCVD,
      showDOM: showDOM ?? this.showDOM,
      showLargeTrades: showLargeTrades ?? this.showLargeTrades,
      showCrosshair: showCrosshair ?? this.showCrosshair,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void setSymbol(String symbol) => state = state.copyWith(symbol: symbol);
  void setInterval(String interval) => state = state.copyWith(interval: interval);
  void setFootprintMode(FootprintMode mode) => state = state.copyWith(footprintMode: mode);
  void toggleLayer(String layer) {
    switch (layer) {
      case 'volume': state = state.copyWith(showVolume: !state.showVolume);
      case 'heatmap': state = state.copyWith(showHeatmap: !state.showHeatmap);
      case 'walls': state = state.copyWith(showLiquidityWalls: !state.showLiquidityWalls);
      case 'imbalance': state = state.copyWith(showImbalance: !state.showImbalance);
      case 'vp': state = state.copyWith(showVP: !state.showVP);
      case 'cvd': state = state.copyWith(showCVD: !state.showCVD);
      case 'dom': state = state.copyWith(showDOM: !state.showDOM);
      case 'largeTrades': state = state.copyWith(showLargeTrades: !state.showLargeTrades);
      case 'crosshair': state = state.copyWith(showCrosshair: !state.showCrosshair);
    }
  }
}

// ─── Market Data State ────────────────────────────────────────────

// ─── Market Data State ────────────────────────────────────────────

class MarketState {
  final List<CandleData> candles;
  final DepthData? depth;
  final VolumeProfileData volumeProfile;
  final List<FootprintCandle> footprints;
  final List<HeatmapPoint> heatmap;
  final List<LiquidityWall> liquidityWalls;
  final List<TradeData> largeTrades;
  final double cvd;
  final bool isLoading;
  final String? error;

  // کلمه const از سازنده حذف شد
  MarketState({
    this.candles = const [],
    this.depth,
    VolumeProfileData? volumeProfile, // اینجا پارامتر را قابل null تعریف می‌کنیم
    this.footprints = const [],
    this.heatmap = const [],
    this.liquidityWalls = const [],
    this.largeTrades = const [],
    this.cvd = 0,
    this.isLoading = false,
    this.error,
  }) : volumeProfile = volumeProfile ?? VolumeProfileData( // مقداردهی پیش‌فرض در اینجا انجام می‌شود
    levels: [],
    pocPrice: 0,
    vahPrice: 0,
    valPrice: 0,
    hvnPrices: [],
    lvnPrices: [],
    totalVolume: 0,
  );

  MarketState copyWith({
    List<CandleData>? candles,
    DepthData? depth,
    VolumeProfileData? volumeProfile,
    List<FootprintCandle>? footprints,
    List<HeatmapPoint>? heatmap,
    List<LiquidityWall>? liquidityWalls,
    List<TradeData>? largeTrades,
    double? cvd,
    bool? isLoading,
    String? error,
  }) {
    return MarketState(
      candles: candles ?? this.candles,
      depth: depth ?? this.depth,
      volumeProfile: volumeProfile ?? this.volumeProfile,
      footprints: footprints ?? this.footprints,
      heatmap: heatmap ?? this.heatmap,
      liquidityWalls: liquidityWalls ?? this.liquidityWalls,
      largeTrades: largeTrades ?? this.largeTrades,
      cvd: cvd ?? this.cvd,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MarketNotifier extends Notifier<MarketState> {
  final BinanceService _service = BinanceService();
  Timer? _klineTimer;
  Timer? _depthTimer;
  Timer? _vpTimer;
  Timer? _heatmapTimer;
  Timer? _tradeTimer;

  @override
  MarketState build() {
    _initPolling();
    ref.onDispose(() => _dispose());
    return MarketState();
  }


  void _initPolling() {
    final settings = ref.read(settingsProvider);
    _fetchKlines();
    _fetchDepth();
    _fetchVolumeProfile();
    _fetchHeatmap();
    _fetchTrades();

    _klineTimer = Timer.periodic(ChartDefaults.klinePollInterval, (_) => _fetchKlines());
    _depthTimer = Timer.periodic(ChartDefaults.depthPollInterval, (_) => _fetchDepth());
    _vpTimer = Timer.periodic(ChartDefaults.vpPollInterval, (_) => _fetchVolumeProfile());
    _heatmapTimer = Timer.periodic(ChartDefaults.heatmapPollInterval, (_) => _fetchHeatmap());
    _tradeTimer = Timer.periodic(ChartDefaults.tradePollInterval, (_) => _fetchTrades());
  }

  void _dispose() {
    _klineTimer?.cancel();
    _depthTimer?.cancel();
    _vpTimer?.cancel();
    _heatmapTimer?.cancel();
    _tradeTimer?.cancel();
  }

  Future<void> _fetchKlines() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final settings = ref.read(settingsProvider);
      final candles = await _service.getKlines(
        symbol: settings.symbol,
        interval: settings.interval,
        limit: ChartDefaults.klineLimit,
      );

      // Compute CVD
      double cvd = 0;
      for (final c in candles) {
        cvd += c.takerBuyBaseVol - c.sellVolume;
      }

      state = state.copyWith(
        candles: candles,
        cvd: cvd,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _fetchDepth() async {
    try {
      final settings = ref.read(settingsProvider);
      final depth = await _service.getDepth(
        symbol: settings.symbol,
        limit: ChartDefaults.depthLimit,
      );
      final walls = _service.detectLiquidityWalls(depth);
      state = state.copyWith(
        depth: depth,
        liquidityWalls: walls,
      );
    } catch (e) {
      // Silent fail for depth
    }
  }

  Future<void> _fetchVolumeProfile() async {
    try {
      if (state.candles.isEmpty) return;
      final vp = _service.computeVolumeProfile(state.candles);
      state = state.copyWith(volumeProfile: vp);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _fetchHeatmap() async {
    try {
      if (state.candles.isEmpty) return;
      final points = _service.generateHeatmap(
        candles: state.candles,
        depth: state.depth,
        timeBins: ChartDefaults.heatmapTimeBins,
        priceLevels: ChartDefaults.heatmapPriceLevels,
      );
      state = state.copyWith(heatmap: points);
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _fetchTrades() async {
    try {
      final settings = ref.read(settingsProvider);
      final candles = state.candles;
      if (candles.isEmpty) return;

      final startTime = candles.last.openTime - 3600000;
      final trades = await _service.getTrades(
        symbol: settings.symbol,
        limit: ChartDefaults.tradeLimit,
        startTime: startTime,
      );

      // Detect large trades (>10x average)
      final avgQty = trades.isEmpty ? 0 : trades.fold(0.0, (s, t) => s + t.quantity) / trades.length;
      final large = trades.where((t) => t.quantity >= avgQty * 10).map((t) =>
        TradeData(id: t.id, price: t.price, quantity: t.quantity,
          timestamp: t.timestamp, isBuyerMaker: t.isBuyerMaker, isLarge: true)
      ).toList();

      // Build footprint
      final footprints = _service.buildFootprint(trades, candles);

      state = state.copyWith(
        footprints: footprints,
        largeTrades: large,
      );
    } catch (e) {
      // Silent fail
    }
  }

  void changeSymbol(String symbol) {
    ref.read(settingsProvider.notifier).setSymbol(symbol);
    _dispose();
    _initPolling();
  }

  void changeInterval(String interval) {
    ref.read(settingsProvider.notifier).setInterval(interval);
    _dispose();
    _initPolling();
  }
}

// ─── Providers ───────────────────────────────────────────────────

final binanceServiceProvider = Provider<BinanceService>((ref) => BinanceService());

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

final marketProvider = NotifierProvider<MarketNotifier, MarketState>(
  MarketNotifier.new,
);
