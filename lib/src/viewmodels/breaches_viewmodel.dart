import 'package:provider/provider.dart';
import 'package:pwn_check/register.dart';
import 'package:pwn_check/src/models/account_model.dart';
import 'package:pwn_check/src/models/breach_model.dart';
import 'package:pwn_check/src/services/db.dart';
import 'package:stacked/stacked.dart';
import '../../register.dart';

class BreachesViewModel extends BaseViewModel {
  bool _isDisposed = false;
  Db _db;
  AccountModel _account;
  List<BreachModel> _breaches;

  void init(AccountModel account) async {
    print("breaches_viewmodel INIT");
    _account = account;
    _db = await locator.getAsync<Db>();
    _breaches = await _db.fetchBreaches(_account.account);
    _setState();
  }

  List<BreachModel> get breaches => _breaches;
  AccountModel get account => _account;

  void _setState() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
