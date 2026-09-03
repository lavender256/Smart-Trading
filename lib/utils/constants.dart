import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color bgPrimary = Color(0xFF0A0E17);
  static const Color bgSecondary = Color(0xFF111827);
  static const Color bgTertiary = Color(0xFF1F2937);
  static const Color bgCard = Color(0xFF151C2C);

  // Text
  static const Color textPrimary = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Bull / Bear
  static const Color bull = Color(0xFF22C55E);
  static const Color bullLight = Color(0xFF4ADE80);
  static const Color bullDark = Color(0xFF166534);
  static const Color bear = Color(0xFFEF4444);
  static const Color bearLight = Color(0xFFF87171);
  static const Color bearDark = Color(0xFF991B1B);

  // Accent
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accentDark = Color(0xFF1D4ED8);

  // Chart specific
  static const Color gridLine = Color(0xFF1E293B);
  static const Color gridLineStrong = Color(0xFF334155);
  static const Color crosshair = Color(0xFF94A3B8);
  static const Color currentPrice = Color(0xFFFBBF24);
  static const Color volumeBuy = Color(0x4022C55E);
  static const Color volumeSell = Color(0x40EF4444);

  // Volume Profile
  static const Color vpBuy = Color(0xFF22C55E);
  static const Color vpSell = Color(0xFFEF4444);
  static const Color poc = Color(0xFFFBBF24);
  static const Color vah = Color(0xFF60A5FA);
  static const Color val = Color(0xFFF472B6);
  static const Color hvn = Color(0x3022C55E);
  static const Color lvn = Color(0x30EF4444);

  // Heatmap
  static const Color heatBidMax = Color(0xFF22C55E);
  static const Color heatAskMax = Color(0xFFEF4444);
  static const Color heatBidLow = Color(0x1522C55E);
  static const Color heatAskLow = Color(0x15EF4444);

  // Liquidity Walls
  static const Color wallBid = Color(0xFF3B82F6);
  static const Color wallAsk = Color(0xFFF97316);

  // Imbalance
  static const Color imbalance = Color(0xFFEAB308);

  // CVD
  static const Color cvdPositive = Color(0xFF22C55E);
  static const Color cvdNegative = Color(0xFFEF4444);
  static const Color cvdZero = Color(0xFF4B5563);

  // UI
  static const Color border = Color(0xFF1F2937);
  static const Color hover = Color(0xFF374151);
  static const Color active = Color(0xFF3B82F6);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);
  static const Color info = Color(0xFF3B82F6);

  // Large Trade
  static const Color largeTrade = Color(0xFFFF00FF);

  // DOM
  static const Color domBidBg = Color(0x2022C55E);
  static const Color domAskBg = Color(0x20EF4444);
}

class AppDimensions {
  static const double priceScaleWidth = 80;
  static const double timeScaleHeight = 28;
  static const double cvdHeight = 60;
  static const double volumeAreaRatio = 0.18;
  static const double baseVisibleCandles = 80;
  static const double minCandleWidth = 3;
  static const double maxCandleWidth = 80;
  static const double domLevelHeight = 28;
  static const double watchlistItemHeight = 36;
  static const double statsBarHeight = 32;
  static const double toolbarHeight = 48;
  static const double borderRadius = 6;
  static const double borderWidth = 1;
}

class ChartDefaults {
  static const String defaultSymbol = 'BTCUSDT';
  static const String defaultInterval = '1m';
  static const int klineLimit = 200;
  static const int depthLimit = 50;
  static const int tradeLimit = 500;
  static const int vpBins = 100;
  static const int heatmapTimeBins = 20;
  static const int heatmapPriceLevels = 30;
  static const double imbalanceRatio = 3.0;
  static const double wallMultiplier = 3.0;
  static const Duration klinePollInterval = Duration(seconds: 5);
  static const Duration depthPollInterval = Duration(seconds: 2);
  static const Duration vpPollInterval = Duration(seconds: 15);
  static const Duration heatmapPollInterval = Duration(seconds: 10);
  static const Duration tradePollInterval = Duration(seconds: 8);
}
