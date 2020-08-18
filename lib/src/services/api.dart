import 'package:flutter/material.dart';
import 'package:flutter_user_agent/flutter_user_agent.dart';
import 'package:http/http.dart';
import '../models/breach_model.dart';
import '../models/paste_model.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../keys.dart';

class API {
  static const baseURL = 'https://haveibeenpwned.com/api/v3';
  static const pwdURL = 'https://api.pwnedpasswords.com/range/';
  Map<String, String> headers = {
    "hibp-api-key": HIBP_KEY,
  };

  void testPwd() async {
    final pwd = "qwerty";
    final digest = await checkPwd(password: pwd);
    print('$digest');
  }

  Future<void> test() async {
    // final breaches = await getBreaches(domain: "afroandy200@aol.com");
    final breaches = await getBreaches(domain: "adobe.com");
    // final breaches = await getBreachNames(account: "afroandy200@aol.com");

    // final breaches = await getPastes(account: "asalmon9989@gmail.com");
    print('Test: ${breaches.length} breaches found.');
    breaches.forEach((element) {
      print(element);
    });
  }

  Future<void> addUserAgent() async {
    if (!headers.containsKey('user-agent')) {
      final ua = await FlutterUserAgent.getPropertyAsync('userAgent');
      headers["user-agent"] = ua;
    }
  }

  Future<List<BreachModel>> getBreaches({String account, String domain}) async {
    if (account != null && domain != null) {
      throw ArgumentError(
          "Account and domain cannot both be passed to getBreaches");
    }
    await addUserAgent();
    String url;
    if (account != null) {
      url = "$baseURL/breachedaccount/$account?truncateResponse=false";
    } else if (domain != null) {
      url = "$baseURL/breaches?domain=$domain";
    } else {
      url = "$baseURL/breaches";
    }
    final Response response = await get(url, headers: headers);
    if (response.statusCode == 404) {
      return <BreachModel>[];
    }
    final results = json.decode(response.body);
    return results
        .map<BreachModel>((item) => BreachModel.fromJson(item))
        .toList();
  }

  Future<List<String>> getBreachNames({@required String account}) async {
    await addUserAgent();
    String url = "$baseURL/breachedaccount/$account";
    final Response response = await get(url, headers: headers);
    if (response.statusCode == 404) {
      return <String>[];
    }
    final results = json.decode(response.body);
    return results.map<String>((item) => item["Name"] as String).toList();
  }

  // Future<BreachModel> getBreach({@required String name})

  Future<List<PasteModel>> getPastes({@required String account}) async {
    await addUserAgent();
    final url = "$baseURL/pasteaccount/$account";
    final Response response = await get(url, headers: headers);
    if (response.statusCode == 404) {
      return <PasteModel>[];
    } else if (response.statusCode == 400) {
      //throw Error();
      return <PasteModel>[];
    }
    final results = json.decode(response.body);
    return results
        .map<PasteModel>((item) => PasteModel.fromJson(item))
        .toList();
  }

  Future<int> checkPwd({@required String password}) async {
    await addUserAgent();
    final hash = hashPassword(password: password);
    final prefix = hash.substring(0, 5);
    final url = "$pwdURL/$prefix";
    Map<String, String> pwdHeaders = Map<String, String>.from(headers);
    pwdHeaders["Add-Padding"] = "true";
    final Response response = await get(url, headers: pwdHeaders);

    final results = response.body;
    int matches = checkPrefixAgainstResults(hash, prefix, results);
    return matches;
  }

  int checkPrefixAgainstResults(
    String passwordHash,
    String prefix,
    String results,
  ) {
    List<String> resList = results.split("\n");
    print("checking against ${resList.length} results");
    //
    int index = resList.indexWhere((element) {
      if (passwordHash == "$prefix${element.substring(0, 35)}".toLowerCase()) {
        return true;
      }
      return false;
    });
    return index != -1 ? int.parse(resList[index].substring(36)) : 0;
  }

  String hashPassword({@required String password}) {
    final bytes = utf8.encode(password);
    final digest = sha1.convert(bytes);
    return digest.toString().toLowerCase();
  }
}
