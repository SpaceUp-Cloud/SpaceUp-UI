import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/pages/home_page.dart';
import 'package:spaceup_ui/pages/login_page.dart';
import 'package:spaceup_ui/ui_data.dart';
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

  static void showMessage(BuildContext context, String msg,
      {int durationInSeconds = 2}) {

    final snackBar = SnackBar(content: Text(msg), duration: Duration(seconds: durationInSeconds),);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<Map<String, String>> getJWT(BuildContext context) async {
    checkJWT(context);
    String jwt = (await Settings().getString("jwt", ""))!;
    Map<String, String> headers = {
      "Authorization": 'Bearer $jwt',
      "Content-type": 'application/json'
    };

    return headers;
  }

  static Future<void> logout(BuildContext context) async {
    Settings().save("jwt", "");

    bool rememberLogin = await Settings().getBool("rememberLogin", false);
    if(!rememberLogin) {
      Settings().save("server", "https://");
      Settings().save("username", "");
      Settings().save("password", "");
    }

    Get.offAll(() => LoginPage());
  }

  static Future<void> login(BuildContext context) async {
    Get.offAll(() => HomePage("Home"));
  }

  static Future<void> checkJWT(BuildContext context) async {
    final jwt = (await Settings().getString("jwt", ""))!;
    try {
      if(!JwtDecoder.isExpired(jwt)) {
        // When are on the login page, we want to login
        var currentRoute = Get.currentRoute;
        if(currentRoute == UIData.loginRoute || currentRoute == "/") {
          Util.login(context);
        }
      } else {
        print("JWT is expired!");
        Util.logout(context);
      }
    } catch(fe) {
      print("Token is invalid");
    }
  }
}

class JWT {
  String username;
  String access_token;
  String token_type;
  int expires_in;

  JWT({
    required this.username,
    required this.access_token,
    required this.token_type,
    required this.expires_in
  });

  factory JWT.fromJson(Map<String, dynamic> json) => _jwtFromJson(json);
}

JWT _jwtFromJson(Map<String, dynamic> json) {
  return JWT(
      username: json["username"] as String,
      access_token: json["access_token"] as String,
      token_type: json["token_type"] as String,
      expires_in: json["expires_in"] as int
  );
}