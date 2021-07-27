import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

class Util {

  bool get isDesktop => (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  bool get isMobile => (Platform.isIOS || Platform.isAndroid);
  bool get isWeb => kIsWeb ? true : false;

  static void showFeedback(BuildContext context, String msg) {
    print(msg);
    var feedback;
    var snackBar;

    try {
      feedback = json.decode(msg) as Map<String, dynamic>;
    } catch (ex) {
      feedback = json.decode(msg).cast<Map<String, dynamic>>();
    }

    if(feedback is List) {
      for(var f in feedback) {
        if(f != null && f["info"] != null) {
          snackBar = SnackBar(content: Text(f["info"]!),);
        }

        if(f != null && f["error"] != null) {
          snackBar = SnackBar(content: Text(f["error"]!),);
        }
      }
    } else {
      if(feedback != null && feedback["info"] != null) {
        snackBar = SnackBar(content: Text(feedback["info"]!),);
      }

      if(feedback != null && feedback["error"] != null) {
        snackBar = SnackBar(content: Text(feedback["error"]!),);
      }
    }

    if(snackBar != null) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}