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
