import 'package:flutter/material.dart';
import 'package:pwn_check/src/viewmodels/passwords_viewmodel.dart';
import 'package:stacked/stacked.dart';

class PasswordsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PasswordsViewModel>.reactive(
      builder: (context, model, _) => Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text("Passwords"),
        ),
        body: Container(
          margin: EdgeInsets.all(10.0),
          child: Column(
            children: [
              TextField(
                controller: model.textController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter a password to check for breaches',
                ),
                obscureText: true,
                onSubmitted: (value) async {
                  if (value == "") return;
                  final hits = await model.checkPassword(value);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: hits > 0 ? Text("Oh no!") : Text("Good!"),
                      content: hits > 0
                          ? Text(
                              "Password has been found in $hits breaches! Don't use this as a password!",
                            )
                          : Text(
                              "This password had not been found in any breaches!",
                            ),
                      actions: <Widget>[
                        FlatButton(
                          child: Text("Dismiss"),
                          onPressed: () {
                            Navigator.of(context).pop();
                            model.clearText();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              model.loading ? CircularProgressIndicator() : Container(),
            ],
          ),
        ),
      ),
      viewModelBuilder: () => PasswordsViewModel(),
    );
  }
}
