import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:pwn_check/src/widgets/breach_item.dart';
import 'package:stacked/stacked.dart';
import '../models/index.dart';
import '../viewmodels/breaches_viewmodel.dart';

class BreachesView extends StatelessWidget {
  final AccountModel account;
  BreachesView({this.account});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<BreachesViewModel>.reactive(
      builder: (context, model, _) => Scaffold(
        appBar: AppBar(
          title: Text("${model.account.account} breaches"),
        ),
        body: model.breaches == null
            ? CircularProgressIndicator()
            : ListView.builder(
                itemCount: model.breaches.length,
                itemBuilder: (context, index) =>
                    BreachItem(model.breaches[index]),
              ),
      ),
      viewModelBuilder: () => BreachesViewModel(),
      onModelReady: (model) => model.init(account),
    );
  }
}
