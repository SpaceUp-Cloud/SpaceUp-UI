import 'dart:convert';
import 'dart:ffi';

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

  static const maxSteps = 4;

  // validating forms
  final _formApiKey = GlobalKey<FormState>();
  final _formKeyUser = GlobalKey<FormState>();
  final _formKeySsh = GlobalKey<FormState>();
  final _formKeyFinalize = GlobalKey<FormState>();

  final progressValue = ValueNotifier(0.0);

  // for setup and login
  final urlText = TextEditingController();
  final usernameText = TextEditingController();
  late bool rememberLogin = false;
  late bool autoLogin = false;

  // setup API key from server
  final apikey = TextEditingController();

  // setup user
  bool _isObscurePassword = true;
  bool _isObscurePassword2 = true;
  final passwordText = TextEditingController();
  final passwordText2 =
      TextEditingController(); // For validating if is equal to passwordText

  // setup ssh
  bool _isObscureSshPassword = true;
  bool _isObscureSshPassword2 = true;
  final serverSshText = TextEditingController();
  final usernameSshText = TextEditingController();
  final passwordSshText = TextEditingController();
  final passwordSshText2 = TextEditingController();

  // finish installation
  // ...

  final showProgressBar = ValueNotifier<bool>(false);

  // Update this text for each step you take
  final showStepText = ValueNotifier<String>("");
  final titleText = ValueNotifier<String>("Validate Server");

  // 0 - validate
  // 1 - setup
  // 2 - login
  final showProcess = ValueNotifier<int>(0);

  /*final showCheckUrl = ValueNotifier<bool>(false); // Revert to true
  final showSetUpSpaceUp = ValueNotifier<bool>(true); // Revert to false
  final showLogin = ValueNotifier<bool>(false);*/

  // For progressbar
  double progress = 0.0;

  // If this is true, we can directly go to login
  late bool isValidSetUp = false;

  // And if this is true, well. We can even directly log in.
  late bool isValidJWT = false;

  @override
  void initState() {
    super.initState();
    Util.checkJWT(context)
        .then((value) => {getUserSettings().then((value) => initialize())});
  }

  void initialize() {
    // 1. Check if we have a valid url
    // 2. if yes, check if we are installed correctly
    // 3. login
    if (showProcess == 0 && urlText.value.text.isNotEmpty) {
      _validateUrl().then((value) => {
            if (showProcess.value == 2 &&
                usernameText.value.text.isNotEmpty &&
                passwordText.value.text.isNotEmpty)
              {titleText.value == "Login", _login()}
            else if (showProcess == 1)
              {
                // Assume we have to setup spaceup
                showProgressBar.value = true
              }
          });
    } else {
      // Assume we have to setup spaceup
      titleText.value = "Set API Key";
      showStepText.value = "1 / $maxSteps";
      showProgressBar.value = true;
      progressValue.value = 0.0;
      showProcess.value = 1;
    }

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
        title: AnimatedBuilder(
          animation: titleText,
          builder: (context, _) => Text("SpaceUp - ${titleText.value}"),
        ),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: showProgressBar,
        builder: (context, _) {
          return LinearProgressIndicator(
            //Theme.of(context).primaryColor
            minHeight: 10.0,
            backgroundColor: Theme.of(context).backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            value: progressValue.value,
          );
        },
      ),
      body: Padding(
          padding: EdgeInsets.all(10.0),
          child: AnimatedBuilder(
            animation: showProcess,
            builder: (context, _) {
              switch (showProcess.value) {
                case 0:
                  return _serverUrlForm();
                case 1:
                  return _setupForm();
                case 2:
                  return _loginForm();
                default:
                  {
                    return Container(
                      child: Text('Bug! Unknown Process: ${showProcess.value}'),
                    );
                  }
              }
            },
          )),

    );

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
                  onPressed: _validateUrl))
        ],
      ),
    );
  }

  // Maybe better an animatedbuilder to switch between forms
  AnimatedBuilder _setupForm() {
    return AnimatedBuilder(
      animation: showStepText,
      builder: (context, _) {
        switch (showStepText.value) {
          case "1 / $maxSteps":
            {
              return _apiKeyForm();
            }
          case "2 / $maxSteps":
            {
              return _userForm();
            }
          case "3 / $maxSteps":
            {
              return _sshForm();
            }
          case "4 / $maxSteps":
            {
              return _finalizeForm();
            }
          default:
            {
              return Container(
                child: Text("Unknown step. That's a bug!"),
              );
            }
        }
      },
    );
  }

  Form _apiKeyForm() {
    return Form(
      key: _formApiKey,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10.0),
            child: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please add your API Key. "
                      "You can find it in the logs on startup.";
                }
                return null;
              },
              controller: apikey,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'API Key',
                hintText: 'You find it in the startup logs from SpaceUp.',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formApiKey.currentState!.validate()) {
                setState(() {
                  titleText.value = "Create SpaceUp User";
                  showStepText.value = "2 / $maxSteps";
                  progressValue.value = 0.25;
                });
              }
            },
            child: Text("Next"),
          )
        ],
      ),
    );
  }

  Form _userForm() {
    return Form(
        key: _formKeyUser,
        child: Column(
          children: [
            // Username field
            Padding(
              padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
              child: TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'You need a username';
                  }
                  return null;
                },
                controller: usernameText,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Username',
                  hintText: 'Username',
                ),
              ),
            ),
            // Password field
            Padding(
              padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
              child: TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'You need a password';
                  }
                  return null;
                },
                obscureText: _isObscurePassword,
                controller: passwordText,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_isObscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isObscurePassword = !_isObscurePassword;
                        });
                      },
                    )),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
              child: TextFormField(
                validator: (value) {
                  var password1 = passwordText.value.text;
                  if (value == null || value.isEmpty) {
                    return 'You need a password';
                  } else if (value != password1) {
                    return "Passwords are not identical";
                  }
                  return null;
                },
                obscureText: _isObscurePassword2,
                controller: passwordText2,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Repeat password',
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_isObscurePassword2
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isObscurePassword2 = !_isObscurePassword2;
                        });
                      },
                    )),
              ),
            ),
            ElevatedButton(
                onPressed: () {
                      if (_formKeyUser.currentState!.validate()) {
                          // submit user
                          //_processSetupUser()
                          setState(() {
                            titleText.value = "Set SSH credentials";
                            showStepText.value = "3 / $maxSteps";
                            progressValue.value = 0.50;
                          });
                        }
                    },
                child: Text('Next'))
          ],
        ));
  }

  Form _sshForm() {
    return Form(
        key: _formKeySsh,
        child: Column(
          children: [
            // Which server SpaceUp should connect with
            Padding(
              padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
              child: TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "You need to define "
                        "which SSH server SpaceUp should connect with.";
                  }
                  return null;
                },
                controller: serverSshText,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'SSH Server',
                    hintText: 'The server SpaceUp should connect with.',
                  )
              ),
            ),
            // Username field
            Padding(
              padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
              child: TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'You need a username';
                  }
                  return null;
                },
                controller: usernameSshText,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Ssh Username',
                  hintText: 'Ssh Username',
                ),
              ),
            ),
            // Password field
            Padding(
              padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
              child: TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'You need a password';
                  }
                  return null;
                },
                obscureText: _isObscureSshPassword,
                controller: passwordSshText,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'SSH Password',
                    hintText: 'SSH Password',
                    suffixIcon: IconButton(
                      icon: Icon(_isObscureSshPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isObscureSshPassword = !_isObscureSshPassword;
                        });
                      },
                    )),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
              child: TextFormField(
                validator: (value) {
                  var password1 = passwordSshText.value.text;
                  if (value == null || value.isEmpty) {
                    return 'You need a password';
                  } else if (value != password1) {
                    return "Passwords are not identical";
                  }
                  return null;
                },
                obscureText: _isObscureSshPassword2,
                controller: passwordSshText2,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Repeat password',
                    hintText: 'SSH Password',
                    suffixIcon: IconButton(
                      icon: Icon(_isObscureSshPassword2
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isObscureSshPassword2 = !_isObscureSshPassword2;
                        });
                      },
                    )),
              ),
            ),
            ElevatedButton(
                onPressed: () {
                      if (_formKeySsh.currentState!.validate())
                        {
                          // submit user
                          //_processSetupUser()
                          setState(() {
                            titleText.value = "Finish it!";
                            showStepText.value = "4 / $maxSteps";
                            progressValue.value = 0.75;
                          });
                        }
                    },
                child: Text('Next'))
          ],
        ));
  }

  Form _finalizeForm() {
    return Form(
        key: _formKeyFinalize,
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              if(_formKeyFinalize.currentState!.validate()) {
                Util.showMessage(context, "Great! You finished the SpaceUp setup!");
                setState(() {
                  showProgressBar.value = false;
                  titleText.value = "Login";
                  showProcess.value = 2;
                });
              }
            },
            child: Text("Next"),
          ),
        )
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
                onPressed: _login)),
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

    final url = urlText.value.text;
    try {
      if (url.isNotEmpty) {
        var uri = Uri.tryParse('$url/api/system/installed');
        var response = await client.get(uri!);
        print(response.body);
        try {
          var parsed = json.decode(response.body).cast<String, dynamic>();
          if (parsed["isInstalled"] == true) {
            showProcess.value = 2;
          } else {
            showProcess.value = 1;
          }
          Settings().save("server", url);
          Util.showMessage(context, "Connected with $url",
              durationInSeconds: 5);
        } catch (ex) {
          Util.showMessage(context, "Unable to validate installation for $url",
              durationInSeconds: 5);
          Error();
        }
      }
    } catch (ex) {
      Util.showMessage(context, "Cannot connect to $url", durationInSeconds: 5);
      Error();
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

        if (autoLogin) {
          Util.login(context);
        }
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
    bool isRememberLogin = await Settings().getBool("rememberLogin", false);
    bool isAutoLogin = await Settings().getBool("autoLogin", false);
    print("Remember login: $isRememberLogin");
    print("Auto login: $isAutoLogin");

    setState(() {
      rememberLogin = isRememberLogin;
      autoLogin = isAutoLogin;
    });

    if (isRememberLogin) {
      urlText.text = (await Settings().getString("server", "https://"))!;
      usernameText.text = (await Settings().getString("username", ""))!;
      passwordText.text = (await Settings().getString("password", ""))!;
    }
  }
}
