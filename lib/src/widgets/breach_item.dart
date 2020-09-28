import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:pwn_check/src/models/index.dart';

class BreachItem extends StatelessWidget {
  BreachModel breach;

  BreachItem(this.breach);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 10.0,
        left: 20.0,
        right: 20.0,
      ),
      // margin: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //   children: [
          //     Text(breach.name),
          //     Text(DateFormat('MMMM dd yyyy').format(breach.breachDate))
          //   ],
          // ),
          Text(
            breach.name,
            textScaleFactor: 1.2,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              // fontSize: DefaultTextStyle.of(context).style.fontSize * 1.2),
            ),
          ),
          Text(DateFormat('MMMM dd yyyy').format(breach.breachDate)),
          Container(
            child: Html(
                data: breach.description,
                onLinkTap: (url) async {
                  if (await canLaunch(url)) launch(url);
                }),
          ),
          Text(
            "${breach.dataClasses.join(', ')}",
            textScaleFactor: .9,
            style: TextStyle(color: Colors.red[400]),
          ),
          Divider(
            thickness: 1.0,
          ),
        ],
      ),
    );
  }
}
