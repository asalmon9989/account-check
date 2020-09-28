import 'package:flutter/material.dart';
import 'package:pwn_check/register.dart';
import 'package:pwn_check/src/viewmodels/accounts_viewmodel.dart';
import 'package:pwn_check/src/views/add_account_view.dart';
import 'package:pwn_check/src/views/breaches_view.dart';
import 'package:stacked/stacked.dart';

final List<Map<String, dynamic>> dummy = [
  {"account": "afroandy2000@aol.com", "breaches": 3},
  {"account": "afrgfoandy2000@aol.com", "breaches": 3},
  {"account": "afroandy2000@aol.com", "breaches": 3},
  {"account": "afw2roandy2007770@aol.com", "breaches": 0},
  {"account": "11afroandy2000@aol.com", "breaches": 3},
];

final debugMode = false;

class AccountsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // final model = Provider.of<AccountsModel>(context);
    return ViewModelBuilder<AccountsViewModel>.reactive(
      builder: (
        BuildContext context,
        AccountsViewModel model,
        _,
      ) {
        return Scaffold(
          floatingActionButton: debugMode
              ? FloatingActionButton(
                  onPressed: model.dump,
                  child: Icon(Icons.bug_report),
                )
              : null,
          appBar: AppBar(
            title: Text("My Accounts"),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddAcountView(
                      onSubmitted: (account) => model.addAccount(
                        account,
                        fetchBreaches: true,
                      ),
                    ),
                  ),
                ),
              ),
              debugMode
                  ? IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => model.deleteData(),
                    )
                  : Container(),
              debugMode
                  ? IconButton(
                      icon: Icon(Icons.warning),
                      onPressed: () => model.deleteDb(),
                    )
                  : Container(),
            ],
          ),
          body: model.accounts == null || model.accounts.length == 0
              ? Center(
                  child: Text("No account entered yet!"),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    print("Refresh!1!... aahaha");
                    // await model.refreshBreachCounts();
                  },
                  child: ListView.builder(
                    itemBuilder: (context, index) => ListTile(
                      title: Text(model.accounts[index].account),
                      subtitle: Text(
                        "${model.accounts[index].breachCount} breaches ${model.accounts[index].pasteCount} pastes",
                      ),
                      trailing: model.accounts[index].breachCount == 0
                          ? null
                          : IconButton(
                              icon: Icon(Icons.keyboard_arrow_right),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BreachesView(
                                    account: model.accounts[index],
                                  ),
                                ),
                              ),
                            ),
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Delete"),
                            content: Text("Delete this account?"),
                            actions: <Widget>[
                              FlatButton(
                                child: Text("Yes"),
                                onPressed: () {
                                  print("Deleting!");
                                  model.deleteAccount(
                                      model.accounts[index].account);
                                  Navigator.of(context).pop();
                                },
                              ),
                              FlatButton(
                                child: Text("No"),
                                onPressed: () {
                                  print("Not deleting!");
                                  Navigator.of(context).pop();
                                },
                              )
                            ],
                          ),
                        );
                        print(model.accounts[index].account);
                      },
                    ),
                    itemCount: model.accounts.length,
                  ),
                ),
        );
      },
      viewModelBuilder: () => locator<AccountsViewModel>(),
      onModelReady: (AccountsViewModel model) => model.init(),
      disposeViewModel: false,
    );
  }
}
