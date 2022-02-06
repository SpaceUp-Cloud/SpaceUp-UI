import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/retry.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:http/http.dart' as http;
import 'package:spaceup_ui/ui_data.dart';
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
  late bool rememberLogin = false;

  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    Util.checkJWT(context);
    getUserSettings();
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);

    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
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
                    hintText: 'https://your.server'
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
                  color: theme.colorScheme.secondary,
                  child: Text('Login'),
                  onPressed: _login
                )),
            Container(
              child: CheckboxListTile(
                title: Text('Remember Login?'),
                secondary: Icon(Icons.remember_me_sharp),
                value: rememberLogin,
                onChanged: (bool? value) {
                  setState(() {
                    rememberLogin = value!;
                    Settings().save("rememberLogin", value);
                  });

                },
              ),
            )
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

      print("Login status code: ${response.statusCode}");
      if(response.body.isNotEmpty && response.statusCode == 200) {
        print("Login was successful! ${response.body}");

        Settings().save("jwt", JWT.fromJson(jsonDecode(response.body)).access_token);
        Settings().save("server", url);
        Settings().save("username", username);
        Settings().save("password", password);
        Settings().save("rememberLogin", rememberLogin);

        Util.login(context);
      } else {
        String msg = response.statusCode == 401 ? "Wrong credentials" : "Code: ${response.statusCode}";
        Util.showMessage(context, "Error: $msg");
      }
    } finally {
      client.close();
    }
  }

  Future<void> getUserSettings() async {
    bool isrememberLogin = await Settings().getBool("rememberLogin", false);
    print("Remember login: $isrememberLogin");

    setState(() {
      rememberLogin = isrememberLogin;
    });


    if(isrememberLogin) {
      urlText.text = await Settings().getString("server", "https://");
      usernameText.text = await Settings().getString("username", "");
      passwordText.text = await Settings().getString("password", "");
    }
  }
}