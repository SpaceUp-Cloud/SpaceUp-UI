import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/util.dart';

import '../ui_data.dart';

class LoginPage extends StatefulWidget {
  LoginPage() : super();

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  late ThemeData theme;
  
  final urlText = TextEditingController();
  final usernameText = TextEditingController();
  final passwordText = TextEditingController();
  late bool rememberLogin = false;

  final showSetUpSpaceUp = ValueNotifier<bool>(false);
  final showLogin = ValueNotifier<bool>(false);
  final showCheckUrl = ValueNotifier<bool>(true);

  // If this is true, we can directly go to login
  late bool isValidSetUp = false;
  // And if this is true, well. We can even directly log in.
  late bool isValidJWT = false;

  @override
  void initState() {
    super.initState();
    Util.checkJWT(context);
    getUserSettings();

    // 1. Check if we have a valid url
    // 2. if yes, check if we are installed correctly

    // ... else
    // 1. we have to enter a valid url
    // 2. check if we are installed correctly

    // ... else
    // 1. if not valid
    // 2. show check url
    // 3. check if we are installed correctly
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
          child: AnimatedBuilder(
            animation: showCheckUrl,
            builder: (context, _) {
              if(showCheckUrl.value) {
                return _serverUrlForm();
              } else {
                return AnimatedBuilder(
                    animation: showLogin,
                    builder: (context, _) {
                      return _loginForm();
                    });
              }
            },
          )
        ));

    return scaffold;
  }
  
  Center _serverUrlForm() {
    return Center(
      child: ListView(
        children: [
          Container(
            padding: EdgeInsets.all(10.0),
            child: TextField(
              controller: urlText,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Server Url',
                  hintText: 'https://your.server'),
            ),
          ),
          Container(
              height: 50,
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: MaterialButton(
                  textColor: Colors.white,
                  color: theme.colorScheme.secondary,
                  child: Text('Validate'),
                  onPressed: _validateUrl)
          )
        ],
      ),
    );
  }

  ListView _loginForm() {
    return ListView(
      children: [
        Container(
          padding: EdgeInsets.all(10.0),
          child: TextField(
            controller: usernameText,
            decoration: InputDecoration(
                border: OutlineInputBorder(), labelText: 'Username'),
          ),
        ),
        Container(
          padding: EdgeInsets.all(10.0),
          child: TextField(
            controller: passwordText,
            keyboardType: TextInputType.text,
            obscureText: true,
            decoration: InputDecoration(
                border: OutlineInputBorder(), labelText: 'Password'),
          ),
        ),
        Container(
            height: 50,
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: MaterialButton(
                textColor: Colors.white,
                color: theme.colorScheme.secondary,
                child: Text('Login'),
                onPressed: _login)
        ),
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
    );
  }
  
  Future<void> _validateUrl() async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    try {
      final url = urlText.value.text;
      if(url.isNotEmpty) {
        var uri = Uri.tryParse('$url/api/system/installed');
        var response = await client.get(uri!);
        print(response.body);
        try {
          var parsed = json.decode(response.body).cast<String, dynamic>();
          showCheckUrl.value = false;
          if(parsed["isInstalled"] == true) {
            showLogin.value = true;
          } else {
            showSetUpSpaceUp.value = true;
          }
          Settings().save("server", url);
        } catch(ex) {
          Error();
        }
      }
    } finally {
      client.close();
    }
  }

  Future<void> _login() async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    final username = usernameText.value.text;
    final password = passwordText.value.text;

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
        Settings().save("rememberLogin", rememberLogin);

        Util.login(context);
      } else {
        String msg = response.statusCode == 401
            ? "Wrong credentials"
            : "Code: ${response.statusCode}";
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
      urlText.text = (await Settings().getString("server", "https://"))!;
      usernameText.text = (await Settings().getString("username", ""))!;
      passwordText.text = (await Settings().getString("password", ""))!;
    }
  }
}
