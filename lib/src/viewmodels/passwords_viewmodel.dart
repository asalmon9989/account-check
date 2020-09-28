import 'package:pwn_check/src/services/api.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../../register.dart';

class PasswordsViewModel extends BaseViewModel {
  bool _isDisposed = false;
  final _api = locator.get<API>();
  TextEditingController _textController = TextEditingController();

  TextEditingController get textController => _textController;

  Future<int> checkPassword(String pw) async {
    int hits = await _api.checkPwd(password: pw);
    return hits;
  }

  void clearText() {
    _textController.value = TextEditingValue(text: "");
    _setState();
  }

  void _setState() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
