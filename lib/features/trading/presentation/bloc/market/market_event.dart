abstract class MarketEvent {}

class MarketStartPolling extends MarketEvent {
  final String symbol;
  final String interval;
  MarketStartPolling({required this.symbol, required this.interval});
}

class MarketKlinesPolled extends MarketEvent {}

class MarketDepthPolled extends MarketEvent {}

class MarketStopPolling extends MarketEvent {}