class PasteModel {
  final String source;
  final String id;
  final String title;
  final DateTime date;
  final int emailCount;

  PasteModel.fromJson(Map<String, dynamic> parsedJson)
      : source = parsedJson["Source"],
        id = parsedJson["Id"],
        title = parsedJson["Title"] ?? '',
        date = parsedJson["Date"] != null
            ? DateTime.parse(parsedJson["Date"])
            : null,
        emailCount = parsedJson["EmailCount"];

  PasteModel.fromDb(Map<String, dynamic> parsedJson)
      : source = parsedJson["source"],
        id = parsedJson["sd"],
        title = parsedJson["title"] ?? '',
        date = parsedJson["date"] != null
            ? DateTime.fromMillisecondsSinceEpoch(parsedJson["date"])
            : null,
        emailCount = parsedJson["emailCount"];

  Map<String, dynamic> toDbMap() {
    return {
      "source": source,
      "id": id,
      "title": title,
      "date": date?.millisecondsSinceEpoch,
      "emailCount": emailCount
    };
  }

  @override
  String toString() {
    return '''\n
      source: $source,
      id: $id,
      title: $title,
      date: ${date ?? "?"},
      emailCount: $emailCount
    ''';
  }
}
