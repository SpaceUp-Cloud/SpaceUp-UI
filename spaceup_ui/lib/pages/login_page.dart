import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/retry.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:http/http.dart' as http;
import 'package:spaceup_ui/util.dart';

class LoginPage extends StatefulWidget {
  LoginPage() : super();

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginPage>{
  final urlText = TextEditingController();
  final usernameText = TextEditingController();
  final passwordText = TextEditingController();

  late ThemeData theme;

  @override
  void initState() {
  }

  @override
  Widget build(BuildContext context) {
    checkJWT(context);

    theme = Theme.of(context);
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text("SpaceUp Login"),
      ),
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: ListView(
          children: [
            Container(
              padding: EdgeInsets.all(10.0),
              child: TextField(
                controller: urlText,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Server Url',
                    hintText: 'http://your.server:8080'
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10.0),
              child: TextField(
                controller: usernameText,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Username'
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10.0),
              child: TextField(
                controller: passwordText,
                keyboardType: TextInputType.text,
                obscureText: true,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password'
                ),
              ),
            ),
            Container(
                height: 50,
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: MaterialButton(
                  textColor: Colors.white,
                  color: theme.accentColor,
                  child: Text('Login'),
                  onPressed: _login
                )),
          ],
        ),
      )
    );

    return scaffold;
  }

  Future<void> _login() async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    final username = usernameText.value.text;
    final password = passwordText.value.text;
    final url = urlText.value.text;

    final body = jsonEncode({'username': username, 'password': password });
    try {
      var uri = Uri.tryParse('$url/login');
      print(uri);
      var response = await client.post(uri!,
          headers: {"Content-Type": "application/json"},
          body: body
      );

      if(response.body.isNotEmpty && response.statusCode == 200) {
        Settings().save("jwt", JWT.fromJson(jsonDecode(response.body)).access_token);
        Settings().save("profile_active", url);
        Util.showMessage(context, "Login successful!");
        Navigator.pushNamed(context, UIData.homeRoute);
      }
    } finally {
      client.close();
    }
  }

  Future<void> checkJWT(BuildContext context) async {
    final jwt = await Settings().getString("jwt", "");
    if(!JwtDecoder.isExpired(jwt)) {
      Navigator.pushNamed(context, UIData.homeRoute);
    }
  }
}