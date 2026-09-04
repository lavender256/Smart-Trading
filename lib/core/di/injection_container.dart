import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../../features/trading/data/datasources/binance_remote_datasource.dart';
import '../../features/trading/data/repositories/trading_repository_impl.dart';
import '../../features/trading/domain/repositories/trading_repository.dart';
import '../../features/trading/presentation/bloc/market/market_bloc.dart';
import '../../features/trading/presentation/bloc/settings/settings_bloc.dart';

final sl = GetIt.instance; // sl = Service Locator

Future<void> initDependencies() async {
  // ─── External ─────────────────────────────────────────
  sl.registerLazySingleton(() => http.Client());

  // ─── Data Sources ─────────────────────────────────────
  sl.registerLazySingleton<BinanceRemoteDataSource>(
        () => BinanceRemoteDataSourceImpl(client: sl()),
  );

  // ─── Repositories ─────────────────────────────────────
  sl.registerLazySingleton<TradingRepository>(
        () => TradingRepositoryImpl(remoteDataSource: sl()),
  );

  // ─── BLoCs ────────────────────────────────────────────
  // از registerFactory استفاده می‌کنیم تا با هر بار فراخوانی نمونه جدید ساخته شود
  sl.registerFactory(() => SettingsBloc());
  sl.registerFactory(() => MarketBloc(repository: sl()));
}