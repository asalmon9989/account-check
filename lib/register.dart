import 'package:get_it/get_it.dart';
import 'package:pwn_check/src/services/db.dart';
import 'src/services/local_storage.dart';
import 'src/services/api.dart';
import 'src/viewmodels/accounts_viewmodel.dart';
import 'src/viewmodels/breaches_viewmodel.dart';

GetIt locator = GetIt.instance;

Future<void> setupLocator() {
  locator.registerSingletonAsync(() async => LocalStorage.create());
  locator.registerSingletonAsync(Db.create);
  locator.registerLazySingleton(() => API());
  locator.registerLazySingleton(() => AccountsViewModel());
  locator.registerFactory(() => BreachesViewModel());
}
