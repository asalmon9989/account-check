import 'dart:convert';

class AccountModel {
  final String account;
  DateTime breachesChecked, pastesChecked;
  int breachCount = 0, pasteCount = 0;

  AccountModel({
    this.account,
    this.breachCount,
    this.pasteCount,
    this.breachesChecked,
    this.pastesChecked,
  });

  AccountModel.fromJson(Map<String, dynamic> accountModel)
      : account = accountModel['account'],
        breachCount = accountModel['breachCount'],
        pasteCount = accountModel['pasteCount'],
        breachesChecked = accountModel['breachesChecked'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                accountModel['breachesChecked'])
            : null,
        pastesChecked = accountModel['pastesChecked'] != null
            ? DateTime.fromMillisecondsSinceEpoch(accountModel['pastesChecked'])
            : null;

  Map<String, dynamic> toDbMap() {
    return {
      "account": account,
      "breachesChecked": breachesChecked?.millisecondsSinceEpoch,
      "pastesChecked": pastesChecked?.millisecondsSinceEpoch
    };
  }

  @override
  String toString() {
    return '''
      account: $account,
      breachCount: $breachCount,
      pasteCount: $pasteCount,
      breachesChecked: $breachesChecked,
      pastesChecked: $pastesChecked
    ''';
  }

  Map<String, dynamic> toJson() {
    return {
      "account": account,
      "breachCount": json.encode(breachCount),
      "pasteCount": json.encode(pasteCount)
    };
  }
}
