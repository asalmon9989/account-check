import '../models/account_model.dart';
import '../models/breach_model.dart';
import '../models//paste_model.dart';
import 'db.dart';
import 'api.dart';

class Repository {
  // Fetch breaches from API, add to DB, update last checked
  List<BreachModel> fetchBreaches(String account) {
    // Check when the last time the account breach data was fetched from API

    // Fetch from local db or api
  }
}
