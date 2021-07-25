import 'package:flutter/material.dart';

class Style {
  InkWell createCard(
      BuildContext context, IconData myIcon,
      String cardTitle, String path, MaterialColor bgColor, Color fontColor) {

    return InkWell(
        onTap: () {
          Navigator.pushNamed(context, path);
        },
        child: Card(
          semanticContainer: true,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 4,
          margin: EdgeInsets.fromLTRB(5.0, 15.0, 5.0, 30.0),
          color: bgColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  myIcon,
                  color: fontColor,
                  size: 25,
                ),
                title: Text(
                  cardTitle,
                  style: TextStyle(
                      color: fontColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
            ],
          )
        ));
  }
}