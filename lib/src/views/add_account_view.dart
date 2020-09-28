import 'package:flutter/material.dart';
import 'package:pwn_check/src/views/accounts_view.dart';
import '../services/local_storage.dart';

import '../../register.dart';

class AddAcountView extends StatefulWidget {
  Function(String) onSubmitted;
  bool loading = false;
  AddAcountView({@required this.onSubmitted});
  @override
  _AddAcountViewState createState() => _AddAcountViewState();
}

class _AddAcountViewState extends State<AddAcountView> {
  LocalStorage _storage = locator<LocalStorage>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Account"),
      ),
      body: Container(
        margin: EdgeInsets.all(10.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter an email account or domain',
              ),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (value) async {
                setState(() {
                  widget.loading = true;
                });
                await widget.onSubmitted(value);
                setState(() {
                  widget.loading = false;
                });
                Navigator.pop(context);
              },
            ),
            widget.loading ? CircularProgressIndicator() : Container(),
          ],
        ),
      ),
    );
  }
}
