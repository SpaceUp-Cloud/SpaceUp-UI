import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';

import '../ui_data.dart';
import '../util.dart';

class AuthenticationService {
  static Future<void> login({
    BuildContext? context,
    username,
    password,
    remember: true,
    manuallyLogout: true,
    viaForm: false
  }) async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    final body = jsonEncode({'username': username, 'password': password});
    try {
      var url = await URL().serverUrl;
      var uri = Uri.tryParse('$url/login');
      var response = await client.post(uri!,
          headers: {"Content-Type": "application/json"}, body: body);

      print("Login status code: ${response.statusCode}");
      print(response.body);
      if (response.body.isNotEmpty && response.statusCode == 200) {
        print("Login was successful! ${response.body}");

        Settings()
            .save("jwt", JWT.fromJson(jsonDecode(response.body)).access_token);

        Settings().save("username", username);
        Settings().save("password", password);
        Settings().save("rememberLogin", remember);
        Settings().save("manuallyLogout", manuallyLogout);

        // Login in if user initiated or we haven't been log out manually
        if(viaForm) {
          Util.login();
        }
      } else {
        var serverMsg = "";
        try {
          serverMsg = response.body.isNotEmpty
              ? jsonDecode(response.body)["_embedded"]["errors"][0]["message"]
              : "Code: ${response.statusCode}";
        } catch(ex) {
          // There isn't a body
          serverMsg = "Wrong credentials";
        }

        String msg = response.statusCode == 401
            ? "Wrong credentials"
            : serverMsg;
        if(context != null) {
          Util.showMessage(context, "Error: $msg", durationInSeconds: 10);
        }
      }
    } finally {
      client.close();
    }
  }
}