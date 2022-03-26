import 'package:flutter/material.dart';

class SUGradient {

  static get gradientContainer {
    final gradientContainer = Container(
      decoration: boxDecoration
    );

    return gradientContainer;
  }

  static BoxDecoration get boxDecoration {
    return BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              Colors.blue,
              Colors.deepPurple,
              Colors.white
            ]
        )
    );
  }
}