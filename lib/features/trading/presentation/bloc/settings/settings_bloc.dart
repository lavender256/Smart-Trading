import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<SettingsSymbolChanged>((event, emit) {
      emit(state.copyWith(symbol: event.symbol));
    });

    on<SettingsIntervalChanged>((event, emit) {
      emit(state.copyWith(interval: event.interval));
    });

    on<SettingsLayerToggled>((event, emit) {
      switch (event.layer) {
        case 'dom':
          emit(state.copyWith(showDOM: !state.showDOM));
          break;
        case 'volume':
          emit(state.copyWith(showVolume: !state.showVolume));
          break;
        case 'heatmap':
          emit(state.copyWith(showHeatmap: !state.showHeatmap));
          break;
      }
    });
  }
}