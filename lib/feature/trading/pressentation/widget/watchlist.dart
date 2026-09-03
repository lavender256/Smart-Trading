import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/market_provider.dart';
import '../../../../utils/constants.dart';


class WatchlistItem {
  final String symbol;
  final double price;
  final double change24h;
  final double volume24h;

  WatchlistItem({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.volume24h,
  });
}

class Watchlist extends ConsumerStatefulWidget {
  const Watchlist({super.key});

  @override
  ConsumerState<Watchlist> createState() => _WatchlistState();
}

class _WatchlistState extends ConsumerState<Watchlist> {
  final List<WatchlistItem> _items = [];

  @override
  void initState() {
    super.initState();
    // Default watchlist items
    _items.addAll([
      WatchlistItem(symbol: 'BTCUSDT', price: 0, change24h: 0, volume24h: 0),
      WatchlistItem(symbol: 'ETHUSDT', price: 0, change24h: 0, volume24h: 0),
      WatchlistItem(symbol: 'BNBUSDT', price: 0, change24h: 0, volume24h: 0),
      WatchlistItem(symbol: 'SOLUSDT', price: 0, change24h: 0, volume24h: 0),
      WatchlistItem(symbol: 'XRPUSDT', price: 0, change24h: 0, volume24h: 0),
      WatchlistItem(symbol: 'DOGEUSDT', price: 0, change24h: 0, volume24h: 0),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);
    final settings = ref.watch(settingsProvider);
    final activeSymbol = settings.symbol;

    // Update current symbol price from candles
    if (market.candles.isNotEmpty) {
      final lastCandle = market.candles.last;
      final double change = market.candles.length > 1
          ? ((lastCandle.close - market.candles.first.open) / market.candles.first.open)
          : 0;
      for (var item in _items) {
        if (item.symbol == activeSymbol) {
          item = WatchlistItem(
            symbol: item.symbol,
            price: lastCandle.close,
            change24h: change,
            volume24h: lastCandle.quoteVolume,
          );
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Watchlist', style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            )),
          ),
          ..._items.map((item) => _buildItem(item, item.symbol == activeSymbol)),
        ],
      ),
    );
  }

  Widget _buildItem(WatchlistItem item, bool isActive) {
    return GestureDetector(
      onTap: () => ref.read(marketProvider.notifier).changeSymbol(item.symbol),
      child: Container(
        height: AppDimensions.watchlistItemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.active.withOpacity(0.15) : Colors.transparent,
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item.symbol, style: TextStyle(
              color: isActive ? AppColors.accent : AppColors.textPrimary,
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            )),
            if (item.price > 0) ...[
              Text(item.price.toStringAsFixed(item.price >= 1 ? 2 : 4),
                style: TextStyle(
                  color: item.change24h >= 0 ? AppColors.bull : AppColors.bear,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              Text('${item.change24h >= 0 ? '+' : ''}${(item.change24h * 100).toStringAsFixed(2)}%',
                style: TextStyle(
                  color: item.change24h >= 0 ? AppColors.bull : AppColors.bear,
                  fontSize: 10,
                ),
              ),
            ] else ...[
              const Text('Loading...', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              const SizedBox(width: 40),
            ],
          ],
        ),
      ),
    );
  }
}
