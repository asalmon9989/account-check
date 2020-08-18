import 'package:flutter/material.dart';
import 'package:pwn_check/src/views/passwords_view.dart';
import './views/accounts_view.dart';

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Pwn Check",
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: onTabTap,
            items: buildBottomNavigationBarItems(),
          ),
          appBar: AppBar(
            title: Text("Pwn Check"),
          ),
          body: buildTabBar()[_currentIndex],
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> buildBottomNavigationBarItems() {
    return <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: new Icon(Icons.account_circle),
        title: new Text('Accounts'),
      ),
      BottomNavigationBarItem(
        icon: new Icon(Icons.lock),
        title: new Text('Passwords'),
      ),
    ];
  }

  final List<Tab> tabs = <Tab>[
    Tab(text: "Accounts"),
    Tab(text: "Passwords"),
  ];

  List<Widget> buildTabBar() {
    return <Widget>[
      AccountsView(),
      PasswordsView(),
    ];
  }

  void onTabTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget dummyView(String str) => Center(
        child: Text(str),
      );
}
