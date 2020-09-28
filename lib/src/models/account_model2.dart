// import 'dart:convert';

// class AccountModel {
//   final String account;
//   List<String> breachNames;
//   List<String> pasteIds;

//   AccountModel({
//     this.account,
//     this.breachNames = const [],
//     this.pasteIds = const [],
//   });

//   AccountModel.fromJson(Map<String, dynamic> accountModel)
//       : account = accountModel['account'],
//         breachNames = accountModel['breachNames'] != null
//             ? List<String>.from(jsonDecode(accountModel['breachNames']))
//             : [],
//         pasteIds = accountModel['pasteIds'] != null
//             ? List<String>.from(jsonDecode(accountModel['pasteIds']))
//             : [];

//   @override
//   String toString() {
//     return '''
//       account: $account,
//       breachNames: $breachNames,
//       pasteIds: $pasteIds
//     ''';
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       "account": account,
//       "breachNames": json.encode(breachNames),
//       "pasteIds": json.encode(pasteIds)
//     };
//   }
// }
