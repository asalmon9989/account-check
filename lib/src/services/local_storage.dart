import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_model.dart';

class LocalStorage {
  SharedPreferences _prefs;

  LocalStorage._create() {
    print("Private constructor");
  }

  static Future<LocalStorage> create() async {
    var instance = LocalStorage._create();
    await instance.initStorage();
    return instance;
  }

  initStorage() async {
    _prefs = await SharedPreferences.getInstance();
  }

  List<AccountModel> getAccounts() {
    try {
      List<String> accountJSON = _prefs.getStringList("accounts");
      if (accountJSON == null) {
        // addDummyData();
        // print("After addDummy1");
        // print("No accounts");
        return [];
      } else {
        // print("INIT Account: ${accountJSON}");
        final accounts = accountJSON
            .map<AccountModel>(
                (account) => AccountModel.fromJson(json.decode(account)))
            .toList();
        print("We made it! ");
        return accounts;
      }
    } catch (err) {
      print("ERROR: $err");
      return [];
      // addDummyData();
      // print("After addDummy2");
    }
  }

  Future<bool> saveAccounts(List<AccountModel> accounts) async {
    print("saveAccounts");
    List<String> accountList =
        accounts.map<String>((account) => json.encode(account)).toList();
    print("After encode in saveAccounts");
    print(accountList);
    return _prefs.setStringList("accounts", accountList);
  }

  void addAccount(String account) {
    AccountModel newAccount = AccountModel(account: account);
    String accountJson = jsonEncode(newAccount);
    List<String> accounts = _prefs.getStringList("accounts");
    accounts.add(accountJson);
    _prefs.setStringList("accounts", accounts);
  }

  SharedPreferences get prefs => _prefs;
}
