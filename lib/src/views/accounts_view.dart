import 'package:flutter/material.dart';

final List<Map<String, dynamic>> dummy = [
  {"account": "afroandy2000@aol.com", "breaches": 3},
  {"account": "afrgfoandy2000@aol.com", "breaches": 3},
  {"account": "afroandy2000@aol.com", "breaches": 3},
  {"account": "afw2roandy2007770@aol.com", "breaches": 0},
  {"account": "11afroandy2000@aol.com", "breaches": 3},
];

class AccountsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) => ListTile(
        title: Text(dummy[index]['account']),
        subtitle: Text(dummy[index]['breaches'].toString()),
        trailing: rightArrow(dummy[index]['breaches'], index),
      ),
      itemCount: 5,
    );
  }

  Widget rightArrow(int count, int index) {
    return count > 0
        ? IconButton(
            icon: Icon(Icons.keyboard_arrow_right),
            onPressed: () {
              print('Go: $index');
            },
          )
        : null;
  }
}
