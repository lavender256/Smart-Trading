class FormatUtils {
  static String formatPrice(dynamic price, {int decimals = 2}) {
    if (price == null) return '--';
    final p = price is double ? price : double.tryParse(price.toString());
    if (p == null || p.isNaN || p.isInfinite) return '--';
    if (p >= 1000) return p.toStringAsFixed(2);
    if (p >= 1) return p.toStringAsFixed(2);
    if (p >= 0.01) return p.toStringAsFixed(4);
    return p.toStringAsFixed(6);
  }

  static String formatVolume(dynamic vol, {bool compact = false}) {
    if (vol == null) return '--';
    final v = vol is double ? vol : double.tryParse(vol.toString());
    if (v == null || v.isNaN || v.isInfinite) return '--';
    if (!compact) return v.toStringAsFixed(2);
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }

  static String formatNumber(dynamic n, {int decimals = 0}) {
    if (n == null) return '--';
    final num = n is int ? n.toDouble() : double.tryParse(n.toString());
    if (num == null || num.isNaN || num.isInfinite) return '--';
    return num.toStringAsFixed(decimals);
  }

  static String formatPercent(dynamic pct) {
    if (pct == null) return '--';
    final p = pct is double ? pct : double.tryParse(pct.toString());
    if (p == null || p.isNaN || p.isInfinite) return '--';
    return '${(p * 100).toStringAsFixed(1)}%';
  }

  static String formatTime(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  static String formatDateTime(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${formatTime(timestampMs)}';
  }

  static String formatDelta(dynamic d) {
    if (d == null) return '--';
    final v = d is double ? d : double.tryParse(d.toString());
    if (v == null || v.isNaN || v.isInfinite) return '--';
    if (v > 0) return '+${formatVolume(v, compact: true)}';
    return formatVolume(v, compact: true);
  }

  static String formatSpread(double spread, double price) {
    if (price <= 0) return '--';
    final pct = (spread / price) * 100;
    return '${formatPrice(spread)} (${pct.toStringAsFixed(3)}%)';
  }

  static int priceDecimals(double price) {
    if (price >= 10000) return 1;
    if (price >= 100) return 2;
    if (price >= 1) return 2;
    if (price >= 0.01) return 4;
    return 6;
  }
}
