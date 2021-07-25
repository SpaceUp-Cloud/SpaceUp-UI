import 'package:flutter/material.dart';

class Style {
  InkWell createCard(
      BuildContext context,
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
          margin: EdgeInsets.all(12),
          color: bgColor,
          child: Center(
            child: Text(
              cardTitle,
              style: TextStyle(
                  color: fontColor, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ));
  }
}