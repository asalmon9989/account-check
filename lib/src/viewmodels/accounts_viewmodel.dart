import 'package:stacked/stacked.dart';
import '../../register.dart';
import '../models/index.dart';
import '../services/api.dart';
import '../services/db.dart';
import '..//services/local_storage.dart';

class AccountsViewModel extends BaseViewModel {
  bool _isDisposed = false;
  int _count = 1;
  List<AccountModel> _accounts;
  LocalStorage _storage;
  final _api = locator.get<API>();
  Db _db;

  void init() async {
    print("accounts_viewmodel INIT");
    // _storage = await locator.getAsync<LocalStorage>();
    _db = await locator.getAsync<Db>();
    // await _storage.prefs.clear();
    // _accounts = _storage.getAccounts();

    _accounts = await _db.fetchAccounts();
    _setState();
    // _accounts =
    //     _storage.prefs.getStringList("accounts").toSet() ?? Set<String>();
    // print(_accounts);
  }

  // void addDummyData() async {
  //   _accounts = [
  //     AccountModel(
  //         account: "afroandy2000@aol.com", breachCount: 2, pasteCount: 0),
  //     AccountModel(
  //         account: "awfulandy200@aol.com", breachCount: 4, pasteCount: 5)
  //   ];
  //   print("Saving");
  //   bool ok = await _storage.saveAccounts(_accounts);
  //   if (ok) {
  //     print("Saved");
  //   } else {
  //     print("NOT Saved");
  //   }
  // }

  // Future<int> getBreachCount(String account) async {
  //   final breachNames = await _api.getBreachNames(account: account);
  //   return breachNames.length;
  // }

  // Future<void> refreshBreachCounts() async {
  //   for (var i = 0; i < _accounts.length; i++) {
  //     List<String> bns =
  //         await _api.getBreachNames(account: _accounts[i].account);
  //     print("$bns");
  //     _accounts[i].breachNames = bns;
  //   }
  //   _storage.saveAccounts(_accounts);
  //   _setState();
  // }

  // void addAccount(String account) async {
  //   List<String> breaches = await _api.getBreachNames(account: account);
  //   //List<String> pastes = await _api.getPastes(account: account);
  //   List<String> pastes = [];
  //   AccountModel newAccount =
  //       AccountModel(account: account, breachNames: breaches, pasteIds: pastes);
  //   _accounts.add(newAccount);
  //   _storage.saveAccounts(_accounts);
  //   _setState();
  // }

  // DEBUG METHODS ----------
  void dump() {
    _db.dump();
  }

  void deleteData() {
    _db.deleteData();
  }

  void deleteDb() {
    // test();
    _db.deleteDb();
  }

  void test() {
    _db.test();
  }

  // ------------------
  void addAccount(String account,
      {bool fetchBreaches = true, bool fetchPastes = true}) async {
    int breachCount = 0, pasteCount = 0;
    AccountModel newAccount = AccountModel(
        account: account,
        breachesChecked: fetchBreaches ? DateTime.now() : null,
        pastesChecked: fetchPastes ? DateTime.now() : null);
    print("acctVM: add account $account");
    final res = await _db.insertAccount(newAccount);
    print("res: $res");
    if (res == null) {
      return;
    }
    if (fetchBreaches) {
      print("fetching breaches");
      List<BreachModel> breaches = await _api.getBreaches(account: account);
      print(breaches);
      breachCount = breaches.length;
      if (breachCount > 0) {
        // Don't wait
        print("$breachCount breaches found for $account");
        _db.insertBreaches(breaches, newAccount);
      }
    }
    if (fetchPastes) {
      print("fetching pastes");
      List<PasteModel> pastes = await _api.getPastes(account: account);
      print("getPastes return: $pastes");
      pasteCount = pastes.length ?? 0;
      if (pasteCount > 0) {
        print("$pasteCount pastes found for $account");
        _db.insertPastes(pastes, newAccount);
      }
    }
    newAccount.breachCount = breachCount;
    newAccount.pasteCount = pasteCount;
    _accounts.add(newAccount);
    _accounts.sort((a, b) => a.account.compareTo(b.account));
    _setState();
  }

  void deleteAccount(String account) async {
    await _db.deleteAccount(account);
    _accounts.removeWhere((element) => element.account == account);
    _setState();
  }

  // void removeAccount(String account) {
  //   int index = _accounts.indexWhere((element) => element.account == account);
  //   if (index != -1) {
  //     _accounts.removeAt(index);
  //     _storage.saveAccounts(_accounts);
  //     _setState();
  //   }
  // }
  void _setState() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  List<AccountModel> get accounts => _accounts;

  int get count => _count;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
