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
