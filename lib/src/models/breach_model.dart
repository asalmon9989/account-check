import 'dart:convert';

class BreachModel {
  final String name;
  final String title;
  final String domain;
  final DateTime breachDate;
  final DateTime addedDate;
  final DateTime modifiedDate;
  final int pwnCount;
  final String description;
  final List<String> dataClasses;
  final bool isVerified;
  final bool isFabricated;
  final bool isSensitive;
  final bool isRetired;
  final bool isSpamList;
  final String logoPath;

  BreachModel.fromJson(Map<String, dynamic> parsedJson)
      : name = parsedJson["Name"],
        title = parsedJson["Title"],
        domain = parsedJson["Domain"],
        breachDate = DateTime.parse(parsedJson["BreachDate"]),
        addedDate = DateTime.parse(parsedJson["AddedDate"]),
        modifiedDate = DateTime.parse(parsedJson["ModifiedDate"]),
        pwnCount = parsedJson["PwnCount"],
        description = parsedJson["Description"],
        dataClasses = List.from(parsedJson["DataClasses"]),
        isVerified = parsedJson["IsVerified"],
        isFabricated = parsedJson["IsFabricated"],
        isSensitive = parsedJson["IsSensitive"],
        isRetired = parsedJson["IsRetired"],
        isSpamList = parsedJson["IsSpamList"],
        logoPath = parsedJson["LogoPath"];

  BreachModel.fromDb(Map<String, dynamic> parsedJson)
      : name = parsedJson["name"],
        title = parsedJson["title"],
        domain = parsedJson["domain"],
        breachDate = parsedJson["breachDate"] != null
            ? DateTime.fromMillisecondsSinceEpoch(parsedJson["breachDate"])
            : null,
        addedDate = parsedJson["addedDate"] != null
            ? DateTime.fromMillisecondsSinceEpoch(parsedJson["addedDate"])
            : null,
        modifiedDate = parsedJson["modifiedDate"] != null
            ? DateTime.fromMillisecondsSinceEpoch(parsedJson["modifiedDate"])
            : null,
        pwnCount = parsedJson["pwnCount"],
        description = parsedJson["description"],
        dataClasses = parsedJson["dataClasses"] != null
            ? List<String>.from(jsonDecode(parsedJson["dataClasses"]))
            : [],
        isVerified = parsedJson["isVerified"] == 1,
        isFabricated = parsedJson["isFabricated"] == 1,
        isSensitive = parsedJson["isSensitive"] == 1,
        isRetired = parsedJson["isRetired"] == 1,
        isSpamList = parsedJson["isSpamList"] == 1,
        logoPath = parsedJson["logoPath"];

  Map<String, dynamic> toDbMap() {
    return {
      "name": name,
      "title": title,
      "domain": domain,
      "breachDate": breachDate?.millisecondsSinceEpoch,
      "addedDate": addedDate?.millisecondsSinceEpoch,
      "modifiedDate": modifiedDate?.millisecondsSinceEpoch,
      "pwnCount": pwnCount,
      "description": description,
      "dataClasses": jsonEncode(dataClasses),
      "isVerified": isVerified ? 1 : 0,
      "isFabricated": isFabricated ? 1 : 0,
      "isSensitive": isSensitive ? 1 : 0,
      "isRetired": isRetired ? 1 : 0,
      "isSpamList": isSpamList ? 1 : 0,
      "logoPath": logoPath,
    };
  }

  @override
  String toString() {
    return '''\n
      name: $name,
      title: $title,
      domain: $domain,
      breachDate: $breachDate,
      addedDate: $addedDate,
      modifiedDate: $modifiedDate,
      pwnCount: $pwnCount,
      description: ${description.substring(0, description.length < 150 ? description.length : 150)},
      dataClasses: $dataClasses,
      isVerified: $isVerified,
      isFabricated: $isFabricated,
      isSensitive: $isSensitive,
      isRetired: $isRetired,
      isSpamList: $isSpamList,
      logoPath: $logoPath;
    ''';
  }
}
