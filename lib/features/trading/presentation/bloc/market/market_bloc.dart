import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/chart_defaults.dart';
import '../../../domain/repositories/trading_repository.dart';
import 'market_event.dart';
import 'market_state.dart';

class MarketBloc extends Bloc<MarketEvent, MarketState> {
  final TradingRepository repository;

  Timer? _klineTimer;
  Timer? _depthTimer;

  String _currentSymbol = ChartDefaults.defaultSymbol;
  String _currentInterval = ChartDefaults.defaultInterval;

  MarketBloc({required this.repository}) : super(const MarketState()) {
    on<MarketStartPolling>(_onStartPolling);
    on<MarketKlinesPolled>(_onKlinesPolled);
    on<MarketDepthPolled>(_onDepthPolled);
    on<MarketStopPolling>(_onStopPolling);
  }

  void _onStartPolling(MarketStartPolling event, Emitter<MarketState> emit) {
    _currentSymbol = event.symbol;
    _currentInterval = event.interval;

    _cancelTimers();

    emit(state.copyWith(status: MarketStatus.loading));

    // در خواست اولیه
    add(MarketKlinesPolled());
    add(MarketDepthPolled());

    // راه‌اندازی تایمرهای پولینگ
    _klineTimer = Timer.periodic(ChartDefaults.klinePollInterval, (_) {
      add(MarketKlinesPolled());
    });

    _depthTimer = Timer.periodic(ChartDefaults.depthPollInterval, (_) {
      add(MarketDepthPolled());
    });
  }

  Future<void> _onKlinesPolled(MarketKlinesPolled event, Emitter<MarketState> emit) async {
    try {
      final candles = await repository.getKlines(
        symbol: _currentSymbol,
        interval: _currentInterval,
      );

      double cvd = 0;
      for (final c in candles) {
        cvd += c.takerBuyBaseVol - c.sellVolume;
      }

      emit(state.copyWith(
        status: MarketStatus.success,
        candles: candles,
        cvd: cvd,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MarketStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDepthPolled(MarketDepthPolled event, Emitter<MarketState> emit) async {
    try {
      final depth = await repository.getDepth(symbol: _currentSymbol);
      emit(state.copyWith(depth: depth));
    } catch (_) {
      // Silent fail for depth polling
    }
  }

  void _onStopPolling(MarketStopPolling event, Emitter<MarketState> emit) {
    _cancelTimers();
  }

  void _cancelTimers() {
    _klineTimer?.cancel();
    _depthTimer?.cancel();
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}