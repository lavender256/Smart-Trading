import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/candle_data.dart';
import '../../models/depth_data.dart';
import '../../models/volume_profile_data.dart';
import '../../models/footprint_data.dart';
import '../../models/liquidity_data.dart';
import '../../models/trade_data.dart';
import '../../utils/constants.dart';
import '../../utils/format_utils.dart';

class ChartEngine extends CustomPainter {
  final List<CandleData> candles;
  final VolumeProfileData volumeProfile;
  final List<FootprintCandle> footprints;
  final List<HeatmapPoint> heatmap;
  final List<LiquidityWall> liquidityWalls;
  final List<TradeData> largeTrades;
  final double cvd;
  final FootprintMode footprintMode;
  final bool showVolume;
  final bool showHeatmap;
  final bool showLiquidityWalls;
  final bool showImbalance;
  final bool showVP;
  final bool showCVD;
  final bool showLargeTrades;
  final bool showCrosshair;
  final int visibleStart;
  final int visibleCount;
  final Offset? crosshairPos;

  ChartEngine({
    required this.candles,
    required this.volumeProfile,
    required this.footprints,
    required this.heatmap,
    required this.liquidityWalls,
    required this.largeTrades,
    required this.cvd,
    required this.footprintMode,
    required this.showVolume,
    required this.showHeatmap,
    required this.showLiquidityWalls,
    required this.showImbalance,
    required this.showVP,
    required this.showCVD,
    required this.showLargeTrades,
    required this.showCrosshair,
    this.visibleStart = 0,
    this.visibleCount = 80,
    this.crosshairPos,
  });

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos, {
    Color color = AppColors.textSecondary,
    double fontSize = 9,
    TextAlign align = TextAlign.left,
  }) {
    if (text.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, height: 1.0)),
      textDirection: TextDirection.ltr,
      textAlign: align,
    );
    tp.layout();
    tp.paint(canvas, pos);
  }

  void _drawDashedLine(
    Canvas canvas,
    double x1,
    double y1,
    double x2,
    double y2,
    Color color, {
    double dashLen = 4.0,
    double gapLen = 3.0,
    double strokeWidth = 1.0,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist <= 0) return;
    final ux = dx / dist;
    final uy = dy / dist;
    double drawn = 0.0;
    bool drawing = true;
    while (drawn < dist) {
      final segLen = drawing ? dashLen : gapLen;
      final remaining = dist - drawn;
      final actualLen = min(segLen, remaining);
      if (drawing) {
        final sx = x1 + ux * drawn;
        final sy = y1 + uy * drawn;
        final ex = x1 + ux * (drawn + actualLen);
        final ey = y1 + uy * (drawn + actualLen);
        canvas.drawLine(Offset(sx, sy), Offset(ex, ey), paint);
      }
      drawn += actualLen;
      drawing = !drawing;
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size, center.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ===================== LAYOUT COMPUTATION =====================
    final chartW = size.width - AppDimensions.priceScaleWidth;
    final chartH = size.height - AppDimensions.timeScaleHeight;
    final volumeH = chartH * AppDimensions.volumeAreaRatio;
    final cvdAreaH = showCVD ? AppDimensions.cvdHeight : 0.0;
    final priceH = chartH - volumeH - cvdAreaH;
    final cvdY = priceH + volumeH;

    // Visible candles
    final visStart = visibleStart.clamp(0, candles.isEmpty ? 0 : candles.length - 1);
    final visEnd = (visStart + visibleCount).clamp(0, candles.length);
    final visCandles = candles.sublist(visStart, visEnd);
    if (visCandles.isEmpty) return;

    final candleW = chartW / visibleCount;

    // Price range
    double pHigh = visCandles.fold(0.0, (m, c) => c.high > m ? c.high : m);
    double pLow = visCandles.fold(999999.0, (m, c) => c.low < m ? c.low : m);
    final pRange = pHigh - pLow;
    if (pRange <= 0) return;
    pHigh += pRange * 0.05;
    pLow -= pRange * 0.05;
    final totalRange = pHigh - pLow;

    double priceToY(double p) => priceH * (1.0 - (p - pLow) / totalRange);
    double yToPrice(double y) => pLow + (1.0 - y / priceH) * totalRange;
    double idxToX(int i) => i * candleW + candleW / 2;

    final bodyW = max(candleW * 0.7, 1.0);

    // ===================== SECTION 1: BACKGROUND =====================
    final bgPaint = Paint()..color = AppColors.bgPrimary;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // ===================== SECTION 2: GRID LINES =====================
    final gridPaint = Paint()
      ..color = AppColors.gridLine
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontal price grid (~10 lines)
    final gridCount = 10;
    for (int i = 0; i <= gridCount; i++) {
      final y = (priceH / gridCount) * i;
      canvas.drawLine(Offset(0, y), Offset(chartW, y), gridPaint);
    }

    // Vertical time grid (auto-compute interval)
    final timeGridInterval = _computeTimeGridInterval(visibleCount);
    for (int i = 0; i < visCandles.length; i++) {
      if (i % timeGridInterval == 0) {
        final x = idxToX(i);
        canvas.drawLine(Offset(x, 0), Offset(x, priceH), gridPaint);
      }
    }

    // ===================== SECTION 3: HEATMAP =====================
    if (showHeatmap && heatmap.isNotEmpty) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, chartW, priceH));
      final maxIntensity = heatmap.fold(0.0, (m, h) => max(m, h.totalIntensity));
      if (maxIntensity > 0) {
        final timeBins = heatmap.map((h) => h.timeBin).toSet().toList()..sort();
        final priceLevels = heatmap.map((h) => h.priceLevel).toSet().toList()..sort();
        final timeBinRange = timeBins.isNotEmpty ? timeBins.last - timeBins.first : 1;
        final priceLevelRange = priceLevels.isNotEmpty ? priceLevels.last - priceLevels.first : 1;

        for (final point in heatmap) {
          final tNorm = timeBinRange > 0 ? (point.timeBin - timeBins.first) / timeBinRange : 0.0;
          final pNorm = priceLevelRange > 0 ? (point.priceLevel - priceLevels.first) / priceLevelRange : 0.0;
          final rx = tNorm * chartW;
          final ry = (1.0 - pNorm) * priceH;
          final rw = (1.0 / max(timeBins.length, 1)) * chartW + 1;
          final rh = (1.0 / max(priceLevels.length, 1)) * priceH + 1;

          final intensityNorm = point.totalIntensity / maxIntensity;
          final bidWeight = point.totalIntensity > 0 ? point.bidIntensity / point.totalIntensity : 0.5;

          final r = (255 * (1.0 - bidWeight) * intensityNorm).round().clamp(0, 255);
          final g = (255 * bidWeight * intensityNorm).round().clamp(0, 255);
          final alpha = (intensityNorm * 180).round().clamp(0, 255);

          final heatPaint = Paint()..color = Color.fromARGB(alpha, r, g, 0);
          canvas.drawRect(Rect.fromLTWH(rx - rw / 2, ry - rh / 2, rw, rh), heatPaint);
        }
      }
      canvas.restore();
    }

    // ===================== SECTION 4: VALUE AREA FILL =====================
    if (showVP && volumeProfile.vahPrice > 0 && volumeProfile.valPrice > 0) {
      final vahY = priceToY(volumeProfile.vahPrice);
      final valY = priceToY(volumeProfile.valPrice);
      if (vahY < valY) {
        final vaPaint = Paint()..color = AppColors.vah.withOpacity(0.08);
        canvas.drawRect(Rect.fromLTWH(0, vahY, chartW, valY - vahY), vaPaint);
      }
    }

    // ===================== SECTION 5: HVN/LVN ZONES =====================
    if (showVP) {
      final tickSize = totalRange / priceH * 2;
      for (final hvnPrice in volumeProfile.hvnPrices) {
        if (hvnPrice >= pLow && hvnPrice <= pHigh) {
          final y = priceToY(hvnPrice);
          final hvnPaint = Paint()..color = AppColors.hvn;
          canvas.drawRect(Rect.fromLTWH(0, y - tickSize, chartW, tickSize * 2), hvnPaint);
        }
      }
      for (final lvnPrice in volumeProfile.lvnPrices) {
        if (lvnPrice >= pLow && lvnPrice <= pHigh) {
          final y = priceToY(lvnPrice);
          final lvnPaint = Paint()..color = AppColors.lvn;
          canvas.drawRect(Rect.fromLTWH(0, y - tickSize, chartW, tickSize * 2), lvnPaint);
        }
      }
    }

    // ===================== SECTION 6: VOLUME BARS =====================
    if (showVolume) {
      final maxVol = visCandles.fold(0.0, (m, c) => c.volume > m ? c.volume : m);
      if (maxVol > 0) {
        for (int i = 0; i < visCandles.length; i++) {
          final c = visCandles[i];
          final barH = (c.volume / maxVol) * volumeH;
          final x = idxToX(i) - bodyW / 2;
          final y = priceH - barH;
          final volPaint = Paint()
            ..color = c.isBullish ? AppColors.volumeBuy : AppColors.volumeSell;
          canvas.drawRect(Rect.fromLTWH(x, y, bodyW, barH), volPaint);
        }
      }
    }

    // ===================== SECTION 7: CANDLESTICKS =====================
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, chartW, priceH));
    final wickPaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final bodyPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < visCandles.length; i++) {
      final c = visCandles[i];
      final x = idxToX(i);
      final wickTopY = priceToY(c.high);
      final wickBottomY = priceToY(c.low);
      final bodyTopY = priceToY(c.bodyTop);
      final bodyBottomY = priceToY(c.bodyBottom);
      final color = c.isBullish ? AppColors.bull : AppColors.bear;

      wickPaint.color = color;
      canvas.drawLine(Offset(x, wickTopY), Offset(x, wickBottomY), wickPaint);

      final actualBodyH = max((bodyBottomY - bodyTopY).abs(), 1.0);
      final actualTop = min(bodyTopY, bodyBottomY);
      bodyPaint.color = color;
      canvas.drawRect(
        Rect.fromLTWH(x - bodyW / 2, actualTop, bodyW, actualBodyH),
        bodyPaint,
      );
    }
    canvas.restore();

    // ===================== SECTION 8: FOOTPRINT =====================
    if (footprints.isNotEmpty && candleW > 20) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, chartW, priceH));
      final fpFontSize = candleW > 40 ? 8.0 : 7.0;
      final halfBody = bodyW / 2;
      final levelHeight = totalRange / priceH;

      for (int ci = 0; ci < visCandles.length; ci++) {
        final candle = visCandles[ci];
        final fpCandle = footprints.where((f) => f.openTime == candle.openTime).firstOrNull;
        if (fpCandle == null || fpCandle.levels.isEmpty) continue;

        final cx = idxToX(ci);
        final levels = fpCandle.levels;

        for (int li = 0; li < levels.length; li++) {
          final lvl = levels[li];
          final y = priceToY(lvl.price);
          final prevPrice = li > 0 ? levels[li - 1].price : lvl.price + levelHeight;
          final lvlH = max((priceToY(prevPrice) - priceToY(lvl.price)).abs(), 8.0);
          final cellY = y - lvlH / 2;

          switch (footprintMode) {
            case FootprintMode.bidAsk:
              {
                final buyText = lvl.buyVolume > 0 ? FormatUtils.formatVolume(lvl.buyVolume, compact: true) : '';
                final sellText = lvl.sellVolume > 0 ? FormatUtils.formatVolume(lvl.sellVolume, compact: true) : '';
                _drawText(canvas, sellText, Offset(cx - halfBody, cellY + 1), color: AppColors.bear, fontSize: fpFontSize);
                final buyTp = TextPainter(
                  text: TextSpan(text: buyText, style: TextStyle(color: AppColors.bull, fontSize: fpFontSize, height: 1.0)),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                )..layout();
                buyTp.paint(canvas, Offset(cx + halfBody - buyTp.width, cellY + 1));
              }
              break;
            case FootprintMode.bidXAsk:
              {
                final product = lvl.buyVolume * lvl.sellVolume;
                final maxProduct = levels.fold(0.0, (m, l) => max(m, l.buyVolume * l.sellVolume));
                final intensity = maxProduct > 0 ? product / maxProduct : 0.0;
                final alpha = (40 + intensity * 180).round().clamp(0, 255);
                final fpBgPaint = Paint()..color = Color.fromARGB(alpha, 255, 165, 0);
                canvas.drawRect(Rect.fromLTWH(cx - halfBody, cellY, bodyW, lvlH), fpBgPaint);
                if (lvl.totalVolume > 0) {
                  _drawText(canvas, FormatUtils.formatVolume(lvl.totalVolume, compact: true), Offset(cx - halfBody + 1, cellY + 1), color: AppColors.textPrimary, fontSize: fpFontSize);
                }
              }
              break;
            case FootprintMode.delta:
              {
                final deltaText = FormatUtils.formatDelta(lvl.delta);
                final deltaColor = lvl.delta >= 0 ? AppColors.bull : AppColors.bear;
                final isImb = lvl.isImbalance;
                if (isImb) {
                  final imbPaint = Paint()..color = AppColors.imbalance.withOpacity(0.2);
                  canvas.drawRect(Rect.fromLTWH(cx - halfBody, cellY, bodyW, lvlH), imbPaint);
                }
                _drawText(canvas, deltaText, Offset(cx - halfBody + 1, cellY + 1), color: isImb ? AppColors.imbalance : deltaColor, fontSize: fpFontSize);
              }
              break;
            case FootprintMode.volume:
              {
                final maxVol = levels.fold(0.0, (m, l) => max(m, l.totalVolume));
                final intensity = maxVol > 0 ? lvl.totalVolume / maxVol : 0.0;
                final alpha = (30 + intensity * 200).round().clamp(0, 255);
                final volColor = lvl.buyVolume >= lvl.sellVolume ? AppColors.bull : AppColors.bear;
                final fpVolBgPaint = Paint()..color = volColor.withAlpha(alpha);
                canvas.drawRect(Rect.fromLTWH(cx - halfBody, cellY, bodyW, lvlH), fpVolBgPaint);
                _drawText(canvas, FormatUtils.formatVolume(lvl.totalVolume, compact: true), Offset(cx - halfBody + 1, cellY + 1), color: AppColors.textPrimary, fontSize: fpFontSize);
              }
              break;
            case FootprintMode.imbalance:
              {
                if (lvl.isImbalance) {
                  final imbPaint = Paint()..color = AppColors.imbalance.withOpacity(0.3);
                  canvas.drawRect(Rect.fromLTWH(cx - halfBody, cellY, bodyW, lvlH), imbPaint);
                  final ratioText = lvl.imbalanceRatio > 0 ? '${lvl.imbalanceRatio.toStringAsFixed(1)}x' : 'IMB';
                  _drawText(canvas, ratioText, Offset(cx - halfBody + 1, cellY + 1), color: AppColors.imbalance, fontSize: fpFontSize);
                }
              }
              break;
          }
        }
      }
      canvas.restore();
    }

    // ===================== SECTION 9: IMBALANCE MARKERS (zoomed out) =====================
    if (showImbalance && footprints.isNotEmpty && candleW <= 20) {
      final imbCirclePaint = Paint()
        ..color = AppColors.imbalance
        ..style = PaintingStyle.fill;
      for (int ci = 0; ci < visCandles.length; ci++) {
        final candle = visCandles[ci];
        final fpCandle = footprints.where((f) => f.openTime == candle.openTime).firstOrNull;
        if (fpCandle == null) continue;
        final hasImbalance = fpCandle.levels.any((l) => l.isImbalance);
        if (hasImbalance) {
          final cx = idxToX(ci);
          final cy = priceToY(candle.high) - 5;
          canvas.drawCircle(Offset(cx, cy), 3.0, imbCirclePaint);
        }
      }
    }

    // ===================== SECTION 10: POC/VAH/VAL LINES =====================
    if (showVP && volumeProfile.pocPrice > 0) {
      // POC
      final pocY = priceToY(volumeProfile.pocPrice);
      if (pocY >= 0 && pocY <= priceH) {
        _drawDashedLine(canvas, 0, pocY, chartW, pocY, AppColors.poc, dashLen: 6, gapLen: 3);
        _drawText(canvas, 'POC', Offset(chartW - 30, pocY - 10), color: AppColors.poc, fontSize: 8);
      }
      // VAH
      if (volumeProfile.vahPrice > 0) {
        final vahY = priceToY(volumeProfile.vahPrice);
        if (vahY >= 0 && vahY <= priceH) {
          _drawDashedLine(canvas, 0, vahY, chartW, vahY, AppColors.vah, dashLen: 6, gapLen: 3);
          _drawText(canvas, 'VAH', Offset(chartW - 30, vahY - 10), color: AppColors.vah, fontSize: 8);
        }
      }
      // VAL
      if (volumeProfile.valPrice > 0) {
        final valY = priceToY(volumeProfile.valPrice);
        if (valY >= 0 && valY <= priceH) {
          _drawDashedLine(canvas, 0, valY, chartW, valY, AppColors.val, dashLen: 6, gapLen: 3);
          _drawText(canvas, 'VAL', Offset(chartW - 30, valY - 10), color: AppColors.val, fontSize: 8);
        }
      }
    }

    // ===================== SECTION 11: VOLUME PROFILE OVERLAY =====================
    if (showVP && volumeProfile.levels.isNotEmpty) {
      final vpMaxWidth = AppDimensions.priceScaleWidth * 0.9;
      final vpMaxPct = volumeProfile.levels.fold(0.0, (m, l) => max(m, l.pctOfTotal));
      if (vpMaxPct > 0) {
        for (final level in volumeProfile.levels) {
          if (level.midPrice < pLow || level.midPrice > pHigh) continue;
          final y = priceToY(level.midPrice);
          final barW = (level.pctOfTotal / vpMaxPct) * vpMaxWidth;
          final buyPct = level.buyPct;
          final r = (255 * (1.0 - buyPct)).round().clamp(0, 255);
          final g = (255 * buyPct).round().clamp(0, 255);
          final vpPaint = Paint()..color = Color.fromARGB(100, r, g, 0);
          final vpX = chartW - barW;
          canvas.drawRect(Rect.fromLTWH(vpX, y - 1, barW, 2), vpPaint);
        }
      }
    }

    // ===================== SECTION 12: LIQUIDITY WALLS =====================
    if (showLiquidityWalls && liquidityWalls.isNotEmpty) {
      for (final wall in liquidityWalls) {
        if (wall.price < pLow || wall.price > pHigh) continue;
        final y = priceToY(wall.price);
        final isBid = wall.side == 'bid';
        final wallColor = isBid ? AppColors.wallBid : AppColors.wallAsk;

        // Glow background
        final glowPaint = Paint()..color = wallColor.withOpacity(0.06);
        canvas.drawRect(Rect.fromLTWH(0, y - 4, chartW, 8), glowPaint);

        // Dashed line
        _drawDashedLine(canvas, 0, y, chartW, y, wallColor, dashLen: 8, gapLen: 4, strokeWidth: 1.5);

        // Label
        final label = 'WALL: ${wall.side.toUpperCase()} ${FormatUtils.formatVolume(wall.quantity, compact: true)}';
        _drawText(canvas, label, Offset(4, y - 12), color: wallColor, fontSize: 8);

        // Price scale marker (small triangle)
        final triPath = Path();
        triPath.moveTo(chartW, y);
        triPath.lineTo(chartW + 8, y - 5);
        triPath.lineTo(chartW + 8, y + 5);
        triPath.close();
        final triPaint = Paint()..color = wallColor;
        canvas.drawPath(triPath, triPaint);
      }
    }

    // ===================== SECTION 13: LARGE TRADE MARKERS =====================
    if (showLargeTrades && largeTrades.isNotEmpty) {
      for (final trade in largeTrades) {
        if (trade.price < pLow || trade.price > pHigh) continue;
        // Find the nearest visible candle
        int? candleIdx;
        for (int ci = 0; ci < visCandles.length; ci++) {
          final c = visCandles[ci];
          if (trade.timestamp >= c.openTime && trade.timestamp < c.openTime + 60000) {
            candleIdx = ci;
            break;
          }
        }
        if (candleIdx == null) continue;
        final cx = idxToX(candleIdx);
        final cy = priceToY(trade.price);
        _drawDiamond(canvas, Offset(cx, cy), 5.0, AppColors.largeTrade);
      }
    }

    // ===================== SECTION 14: CURRENT PRICE LINE =====================
    if (visCandles.isNotEmpty) {
      final lastClose = visCandles.last.close;
      final cpY = priceToY(lastClose);
      if (cpY >= 0 && cpY <= priceH) {
        _drawDashedLine(canvas, 0, cpY, chartW, cpY, AppColors.currentPrice, dashLen: 5, gapLen: 3, strokeWidth: 1.0);
        // Price tag on right
        final tagPaint = Paint()..color = AppColors.currentPrice;
        canvas.drawRect(Rect.fromLTWH(chartW, cpY - 8, AppDimensions.priceScaleWidth, 16), tagPaint);
        final priceLabel = FormatUtils.formatPrice(lastClose);
        final tagTp = TextPainter(
          text: TextSpan(text: priceLabel, style: TextStyle(color: AppColors.bgPrimary, fontSize: 9, fontWeight: FontWeight.bold, height: 1.0)),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();
        tagTp.paint(canvas, Offset(chartW + (AppDimensions.priceScaleWidth - tagTp.width) / 2, cpY - tagTp.height / 2));
      }
    }

    // ===================== SECTION 15: CROSSHAIR & TOOLTIP =====================
    if (showCrosshair && crosshairPos != null) {
      final chX = crosshairPos!.dx;
      final chY = crosshairPos!.dy;

      // Only draw within chart area
      if (chX >= 0 && chX <= chartW && chY >= 0 && chY <= priceH) {
        // Horizontal line
        _drawDashedLine(canvas, 0, chY, chartW, chY, AppColors.crosshair.withOpacity(0.6), dashLen: 3, gapLen: 2);
        // Vertical line
        _drawDashedLine(canvas, chX, 0, chX, priceH, AppColors.crosshair.withOpacity(0.6), dashLen: 3, gapLen: 2);

        // Price label on right
        final chPrice = yToPrice(chY);
        final chPriceStr = FormatUtils.formatPrice(chPrice);
        final chPriceBg = Paint()..color = AppColors.crosshair;
        canvas.drawRect(Rect.fromLTWH(chartW, chY - 8, AppDimensions.priceScaleWidth, 16), chPriceBg);
        final chPriceTp = TextPainter(
          text: TextSpan(text: chPriceStr, style: TextStyle(color: AppColors.bgPrimary, fontSize: 9, fontWeight: FontWeight.bold, height: 1.0)),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();
        chPriceTp.paint(canvas, Offset(chartW + (AppDimensions.priceScaleWidth - chPriceTp.width) / 2, chY - chPriceTp.height / 2));

        // Time label on bottom
        final nearestIdx = (chX / candleW).round().clamp(0, visCandles.length - 1);
        final nearestCandle = visCandles[nearestIdx];
        final timeStr = FormatUtils.formatTime(nearestCandle.openTime);
        final timeBgPaint = Paint()..color = AppColors.crosshair;
        final timeTp = TextPainter(
          text: TextSpan(text: timeStr, style: TextStyle(color: AppColors.bgPrimary, fontSize: 9, height: 1.0)),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();
        final timeTagW = timeTp.width + 8;
        canvas.drawRect(Rect.fromLTWH(chX - timeTagW / 2, priceH, timeTagW, AppDimensions.timeScaleHeight), timeBgPaint);
        timeTp.paint(canvas, Offset(chX - timeTp.width / 2, priceH + 4));

        // OHLCV tooltip box
        final tooltipLines = [
          'O: ${FormatUtils.formatPrice(nearestCandle.open)}',
          'H: ${FormatUtils.formatPrice(nearestCandle.high)}',
          'L: ${FormatUtils.formatPrice(nearestCandle.low)}',
          'C: ${FormatUtils.formatPrice(nearestCandle.close)}',
          'V: ${FormatUtils.formatVolume(nearestCandle.volume, compact: true)}',
        ];
        const tooltipLineH = 13.0;
        final tooltipW = 100.0;
        final tooltipH = tooltipLines.length * tooltipLineH + 8;
        var tx = chX + 12;
        var ty = chY - tooltipH / 2;
        if (tx + tooltipW > chartW) tx = chX - tooltipW - 12;
        if (ty < 0) ty = 2;
        if (ty + tooltipH > priceH) ty = priceH - tooltipH - 2;

        final tooltipBgPaint = Paint()..color = AppColors.bgTertiary.withOpacity(0.92);
        canvas.drawRect(Rect.fromLTWH(tx, ty, tooltipW, tooltipH), tooltipBgPaint);
        final tooltipBorderPaint = Paint()
          ..color = AppColors.border
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;
        canvas.drawRect(Rect.fromLTWH(tx, ty, tooltipW, tooltipH), tooltipBorderPaint);

        for (int li = 0; li < tooltipLines.length; li++) {
          final lineColor = li == 1
              ? AppColors.bull
              : li == 2
                  ? AppColors.bear
                  : AppColors.textSecondary;
          _drawText(canvas, tooltipLines[li], Offset(tx + 4, ty + 4 + li * tooltipLineH), color: lineColor, fontSize: 8);
        }
      }
    }

    // ===================== SECTION 16: CVD =====================
    if (showCVD && cvdAreaH > 0) {
      // Background for CVD area
      final cvdBgPaint = Paint()..color = AppColors.bgSecondary;
      canvas.drawRect(Rect.fromLTWH(0, cvdY, chartW, cvdAreaH), cvdBgPaint);

      // Separator line
      final cvdSepPaint = Paint()
        ..color = AppColors.gridLine
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, cvdY), Offset(chartW, cvdY), cvdSepPaint);

      // Zero line
      final cvdZeroY = cvdY + cvdAreaH / 2;
      final cvdZeroPaint = Paint()
        ..color = AppColors.cvdZero
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, cvdZeroY), Offset(chartW, cvdZeroY), cvdZeroPaint);

      // Compute CVD values for visible candles
      final cvdValues = <double>[];
      double runningCvd = 0.0;
      for (int i = 0; i < visCandles.length; i++) {
        final c = visCandles[i];
        runningCvd += (c.takerBuyBaseVol - c.sellVolume);
        cvdValues.add(runningCvd);
      }

      if (cvdValues.isNotEmpty) {
        // Use the last CVD value from the parameter for absolute reference, but also use accumulated
        // We normalize based on the accumulated range for display
        final cvdMin = cvdValues.fold(0.0, (m, v) => v < m ? v : m);
        final cvdMax = cvdValues.fold(0.0, (m, v) => v > m ? v : m);
        final cvdRange = cvdMax - cvdMin;

        if (cvdRange.abs() > 0.0001) {
          double cvdValToY(double val) {
            return cvdY + cvdAreaH * (1.0 - (val - cvdMin) / cvdRange);
          }

          // Build path
          final cvdPath = Path();
          for (int i = 0; i < cvdValues.length; i++) {
            final px = idxToX(i);
            final py = cvdValToY(cvdValues[i]).clamp(cvdY, cvdY + cvdAreaH);
            if (i == 0) {
              cvdPath.moveTo(px, py);
            } else {
              cvdPath.lineTo(px, py);
            }
          }

          final cvdStrokePaint = Paint()
            ..color = AppColors.cvdPositive
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;
          canvas.drawPath(cvdPath, cvdStrokePaint);

          // Fill above/below zero
          final zeroNorm = (1.0 - (0 - cvdMin) / cvdRange).clamp(0.0, 1.0);
          final zeroScreenY = cvdY + cvdAreaH * (1.0 - zeroNorm);

          // Positive fill (green)
          final posFillPath = Path();
          posFillPath.moveTo(idxToX(0), zeroScreenY);
          for (int i = 0; i < cvdValues.length; i++) {
            final px = idxToX(i);
            final py = cvdValToY(cvdValues[i]).clamp(cvdY, cvdY + cvdAreaH);
            posFillPath.lineTo(px, py);
          }
          posFillPath.lineTo(idxToX(cvdValues.length - 1), zeroScreenY);
          posFillPath.close();
          final posFillPaint = Paint()..color = AppColors.cvdPositive.withOpacity(0.1);
          canvas.drawPath(posFillPath, posFillPaint);

          // Label
          _drawText(canvas, 'CVD', Offset(4, cvdY + 2), color: AppColors.cvdZero, fontSize: 8);
          final lastCvdVal = cvdValues.last;
          final cvdLabel = FormatUtils.formatDelta(lastCvdVal);
          final cvdLabelColor = lastCvdVal >= 0 ? AppColors.cvdPositive : AppColors.cvdNegative;
          _drawText(canvas, cvdLabel, Offset(28, cvdY + 2), color: cvdLabelColor, fontSize: 8);
        }
      }
    }

    // ===================== SECTION 17: TIME SCALE =====================
    final timeScaleY = chartH;
    final timeBgPaint = Paint()..color = AppColors.bgSecondary;
    canvas.drawRect(Rect.fromLTWH(0, timeScaleY, chartW, AppDimensions.timeScaleHeight), timeBgPaint);

    final timeGridInt = _computeTimeGridInterval(visibleCount);
    for (int i = 0; i < visCandles.length; i++) {
      if (i % timeGridInt == 0) {
        final x = idxToX(i);
        final timeStr = FormatUtils.formatTime(visCandles[i].openTime);
        final timeTp = TextPainter(
          text: TextSpan(text: timeStr, style: TextStyle(color: AppColors.textMuted, fontSize: 9, height: 1.0)),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();
        timeTp.paint(canvas, Offset(x - timeTp.width / 2, timeScaleY + 6));
      }
    }

    // ===================== SECTION 18: PRICE SCALE =====================
    final priceScaleX = chartW;
    final priceScaleBgPaint = Paint()..color = AppColors.bgSecondary;
    canvas.drawRect(Rect.fromLTWH(priceScaleX, 0, AppDimensions.priceScaleWidth, size.height), priceScaleBgPaint);

    // Separator line between chart and price scale
    final priceSepPaint = Paint()
      ..color = AppColors.gridLine
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(priceScaleX, 0), Offset(priceScaleX, chartH), priceSepPaint);

    // Price labels
    final decimals = FormatUtils.priceDecimals(pHigh);
    for (int i = 0; i <= gridCount; i++) {
      final y = (priceH / gridCount) * i;
      final price = yToPrice(y);
      final priceStr = FormatUtils.formatPrice(price, decimals: decimals);
      final priceTp = TextPainter(
        text: TextSpan(text: priceStr, style: TextStyle(color: AppColors.textMuted, fontSize: 9, height: 1.0)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout();
      priceTp.paint(canvas, Offset(priceScaleX + AppDimensions.priceScaleWidth - 4 - priceTp.width, y - priceTp.height / 2));
    }

    // Special markers on price scale for POC, VAH, VAL
    if (showVP && volumeProfile.pocPrice > 0) {
      _drawPriceScaleMarker(canvas, priceScaleX, AppDimensions.priceScaleWidth, priceToY, priceH, volumeProfile.pocPrice, pLow, pHigh, 'POC', AppColors.poc);
    }
    if (showVP && volumeProfile.vahPrice > 0) {
      _drawPriceScaleMarker(canvas, priceScaleX, AppDimensions.priceScaleWidth, priceToY, priceH, volumeProfile.vahPrice, pLow, pHigh, 'VAH', AppColors.vah);
    }
    if (showVP && volumeProfile.valPrice > 0) {
      _drawPriceScaleMarker(canvas, priceScaleX, AppDimensions.priceScaleWidth, priceToY, priceH, volumeProfile.valPrice, pLow, pHigh, 'VAL', AppColors.val);
    }

    // Wall markers on price scale
    if (showLiquidityWalls) {
      for (final wall in liquidityWalls) {
        if (wall.price >= pLow && wall.price <= pHigh) {
          final isBid = wall.side == 'bid';
          final wColor = isBid ? AppColors.wallBid : AppColors.wallAsk;
          _drawPriceScaleMarker(canvas, priceScaleX, AppDimensions.priceScaleWidth, priceToY, priceH, wall.price, pLow, pHigh, 'W', wColor);
        }
      }
    }
  }

  void _drawPriceScaleMarker(
    Canvas canvas,
    double scaleX,
    double scaleW,
    double Function(double) priceToY,
    double priceH,
    double price,
    double pLow,
    double pHigh,
    String label,
    Color color,
  ) {
    if (price < pLow || price > pHigh) return;
    final y = priceToY(price);
    if (y < 0 || y > priceH) return;
    // Small colored dot
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(scaleX + 4, y), 3.0, dotPaint);
  }

  int _computeTimeGridInterval(int visibleCount) {
    if (visibleCount <= 20) return 1;
    if (visibleCount <= 50) return 5;
    if (visibleCount <= 100) return 10;
    if (visibleCount <= 200) return 20;
    return 25;
  }
}
