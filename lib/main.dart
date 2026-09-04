import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart' as di;
import 'features/trading/presentation/bloc/market/market_bloc.dart';
import 'features/trading/presentation/bloc/market/market_event.dart';
import 'features/trading/presentation/bloc/settings/settings_bloc.dart';
import 'features/trading/presentation/pages/trading_terminal_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await di.initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (context) => di.sl<SettingsBloc>(),
        ),
        BlocProvider<MarketBloc>(
          create: (context) => di.sl<MarketBloc>()
            ..add(
              MarketStartPolling(
                symbol: 'BTCUSDT',
                interval: '1h',
              ),
            ),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Trading Terminal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const TradingTerminalPage(),
      ),
    );
  }
}