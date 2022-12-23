import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/pages/home_page.dart';
import 'package:spaceup_ui/pages/login_page.dart';
import 'package:spaceup_ui/services/authenticationService.dart';
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

      try {
        final embeddedError = feedback["_embedded"]["errors"][0]["message"];
        if(feedback != null && embeddedError != null) {
          snackBar = SnackBar(content: Text(embeddedError),);
        }
      } catch(ex) {
        // NOP
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

  Future<Map<String, String>> getJWT({bool autologin = true}) async {
    if(autologin) {
      checkJWT();
    }

    String jwt = (await Settings().getString("jwt", ""))!;
    Map<String, String> headers = {
      "Authorization": 'Bearer $jwt',
      "Content-type": 'application/json'
    };

    return headers;
  }

  static Future<void> logout({bool manual = false}) async {
    Settings().save("jwt", "");
    Settings().save("manualLogout", manual); // Shall prevent to login automatically

    bool rememberLogin = await Settings().getBool("rememberLogin", false);
    if(!rememberLogin) {
      Settings().save("server", "");
      Settings().save("username", "");
      Settings().save("password", "");
    }

    Get.offAll(() => LoginPage());
  }

  static Future<void> forgetServer() async {
    await Settings().save("server", "");
  }

  static Future<void> login() async {
    Get.offAll(() => HomePage("Home"));
  }

  static Future<void> checkJWT() async {
    final jwt = (await Settings().getString("jwt", ""))!;
    try {
      if(JwtDecoder.isExpired(jwt)) {
        print("JWT is expired!");
        final remember = await Settings().getBool("rememberLogin", false);
        if(remember) {
          final username = await Settings().getString("username", "");
          final password = await Settings().getString("password", "");
          print("Renew JWT.");
          AuthenticationService.login(
              username: username,
              password: password
          );
        } else {
          Util.logout();
        }
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