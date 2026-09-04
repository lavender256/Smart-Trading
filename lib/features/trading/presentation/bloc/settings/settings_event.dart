abstract class SettingsEvent {}

class SettingsSymbolChanged extends SettingsEvent {
  final String symbol;
  SettingsSymbolChanged(this.symbol);
}

class SettingsIntervalChanged extends SettingsEvent {
  final String interval;
  SettingsIntervalChanged(this.interval);
}

class SettingsLayerToggled extends SettingsEvent {
  final String layer; // 'dom', 'volume', 'heatmap', etc.
  SettingsLayerToggled(this.layer);
}