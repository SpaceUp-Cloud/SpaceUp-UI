import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/SUGradient.dart';
import 'package:spaceup_ui/util.dart';

import '../ui_data.dart';

class LoginPage extends StatefulWidget {
  LoginPage() : super();

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  late ThemeData theme;

  late int maxSteps = 3;
  final nextStep = ValueNotifier<int>(0);

  // validating forms
  final _formValidateServerKey = GlobalKey<FormState>();
  final _formApiKey = GlobalKey<FormState>();
  final _formKeyUser = GlobalKey<FormState>();
  final _formKeySsh = GlobalKey<FormState>();

  final progressValue = ValueNotifier(0.0);

  // for setup and login
  final urlText = TextEditingController();
  final usernameText = TextEditingController();
  late bool rememberLogin = false;
  late bool autoLogin = false;
  late bool manuallyLogout = false;

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

  // If this is true, we can directly go to login
  late bool isValidSetUp = false;

  // And if this is true, well. We can even directly log in.
  late bool isValidJWT = false;

  @override
  void initState() {
    super.initState();

    progressValue.value = (nextStep.value / maxSteps).toDouble();
    nextStep.addListener(() {
      showStepText.value = "${nextStep.value} of / $maxSteps";
      progressValue.value = (nextStep.value / maxSteps).toDouble();
      print("Current progress ${progressValue.value}, step: ${nextStep.value}, maxSteps: $maxSteps");
    });

    getUserSettings().then((value) => initialize());
  }

  void initialize() {
    // 1. Check if we have a valid url
    // 2. if yes, check if we are installed correctly
    // 3. login


    // ... else
    // 1. we have to enter a valid url
    // 2. check if we are installed correctly

    // ... else
    // 1. if not valid
    // 2. show check url
    // 3. check if we are installed correctly
    if (showProcess.value == 0 && urlText.value.text.isNotEmpty) {
      _validateUrl().then((value) async => {
            if (showProcess.value == 2 &&
                usernameText.value.text.isNotEmpty &&
                passwordText.value.text.isNotEmpty) {
                  titleText.value = "Login",
                  if(autoLogin) _login()
            }
            else if (showProcess == 1)
              {
                // Assume we have to setup spaceup
                _setup()
              }
          });
    } else {
      // Assume we have to setup spaceup
      showProcess.value = 0;
    }

  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);

    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        flexibleSpace: SUGradient.gradientContainer,
        title: AnimatedBuilder(
          animation: titleText,
          builder: (context, _) => Text("SpaceUp - ${titleText.value}"),
        ),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: showProgressBar,
        builder: (context, _) {
          return LinearProgressIndicator(
            minHeight: 10.0,
            backgroundColor: Theme.of(context).backgroundColor,
            //valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).pr),
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

  void _setup() {
    titleText.value = "Set API Key";
    nextStep.value = 1;
    showProgressBar.value = true;
    showProcess.value = 1;
  }

  Center _serverUrlForm() {
    return Center(
      child: Form(
        key: _formValidateServerKey,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.0),
              child: TextFormField(
                validator: (text) {
                  if(text == null || text.isEmpty) {
                    return "You have to enter your SpaceUp server";
                  } else {
                    final urlPattern = RegExp("https?://");
                    if(!text.startsWith(urlPattern)) {
                      return "Your URL needs to begin with https:// or http://";
                    }

                  }
                  return null;
                },
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
                child: OutlinedButton(
                    style: flatButtonStyle,
                    child: Text('Validate'),
                    onPressed: () {
                      if(_formValidateServerKey.currentState!.validate()) {
                        _validateUrl();
                      }
                    })
            )
          ],
        ),
      ),
    );
  }

  // Maybe better an animatedbuilder to switch between forms
  AnimatedBuilder _setupForm() {
    return AnimatedBuilder(
      animation: showStepText,
      builder: (context, _) {
        switch (nextStep.value) {
          case 1:
            {
              return _apiKeyForm();
            }
          case 2:
            {
              return _userForm();
            }
          case 3:
            {
              return _sshForm();
            }
          default:
            {
              return Container(
                child: Text("Unknown step: ${nextStep.value}. That's a bug!"),
              );
            }
        }
      },
    );
  }

  @setup
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
          Container(
              height: 50,
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: OutlinedButton(
                style: flatButtonStyle,
                //color: theme.colorScheme.primary,
                onPressed: () {
                  if (_formApiKey.currentState!.validate()) {
                    setState(() {
                      titleText.value = "Create SpaceUp User";
                      nextStep.value = 2;
                    });
                  }
                },
                child: Text("Next"),
              )
          )
        ],
      ),
    );
  }

  @setup
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
            Container(
                height: 50,
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: OutlinedButton(
                    style: flatButtonStyle,
                    onPressed: () {
                      if (_formKeyUser.currentState!.validate()) {
                        // submit user
                        _createUser();
                      }
                    },
                    child: Text('Next')
                )
            )
          ],
        ));
  }

  @setup
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
            Container(
                height: 50,
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: OutlinedButton(
                    style: flatButtonStyle,
                    onPressed: () {
                      if (_formKeySsh.currentState!.validate())
                      {
                        _createSshUser();
                      }
                    },
                    child: Text('Next')
                )
            )
          ],
        ));
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
            child: OutlinedButton(
                style: flatButtonStyle,
                child: Text('Login'),
                onPressed: () => _login(viaForm: true))),
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
        try {
          if(response.statusCode == 200) {
            var parsed = json.decode(response.body).cast<String, dynamic>();
            if (parsed["isInstalled"] == true) {
              showProcess.value = 2;
            } else {
              _setup();
            }
            Settings().save("server", url);
            Util.showMessage(context, "Connected with $url",
                durationInSeconds: 5);
          } else {
            if(response.isRedirect) {
              Util.showMessage(context,
                  "$url tries to redirect. Did you mean 'https'?",
                durationInSeconds: 5
              );
            } else {
              Util.showMessage(context, response.body, durationInSeconds: 5);
            }
          }
        } catch (ex) {
          Util.showMessage(context, "Unable to validate installation for $url.",
              durationInSeconds: 5);
          Error();
        }
      }
    } catch (ex) {
      print(ex);
      showProcess.value = 0;
      Util.showMessage(context, "Cannot connect to $url", durationInSeconds: 5);
      Error();
    } finally {
      client.close();
    }
  }

  Future<void> _login({viaForm: false}) async {
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

        // Login in if user initiated or we haven't been log out manually
        if(viaForm || manuallyLogout == false) {
          Util.login();
        }
      } else {
        final serverMsg = response.body.isNotEmpty
            ? jsonDecode(response.body)["_embedded"]["errors"][0]["message"]
            : "Code: ${response.statusCode}";
        String msg = response.statusCode == 401
            ? "Wrong credentials"
            : serverMsg;
        Util.showMessage(context, "Error: $msg", durationInSeconds: 10);
      }
    } finally {
      client.close();
    }
  }

  Future<void> _createUser() async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    final apiKey = apikey.value.text;
    final username = usernameText.value.text;
    final password = passwordText.value.text;

    final body = jsonEncode({'username': username, 'password': password});

    try {
      var url = urlText.value.text;
      var uri = Uri.tryParse('$url/api/installer/createUser');
      var response = await client.post(uri!,
          headers: {"Content-Type": "application/json", "X-SpaceUp-Key": apiKey},
          body: body
      );

      if (response.statusCode == 200) {
        Settings().save("username", username);
        Settings().save("password", password);

        setState(() {
          titleText.value = "Set SSH credentials";
          nextStep.value = 3;
        });
      } else {
        final msg = response.body;
        Util.showMessage(context, "Error: $msg", durationInSeconds: 5);
      }
    } finally {
      client.close();
    }
  }

  Future<void> _createSshUser() async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    final apiKey = apikey.value.text;
    final username = usernameSshText.value.text;
    final password = passwordSshText.value.text;
    final sshServer = serverSshText.value.text;

    final body = jsonEncode(
        {'username': username, 'password': password, 'server': sshServer}
    );

    try {
      var url = urlText.value.text;
      var uri = Uri.tryParse('$url/api/installer/createSshSetup');
      var response = await client.post(uri!,
          headers: {"Content-Type": "application/json", "X-SpaceUp-Key": apiKey},
          body: body
      );

      if (response.statusCode == 200) {
        _finalizeInstallation();
      } else {
        final msg = response.body;
        Util.showMessage(context, "Error: $msg", durationInSeconds: 5);
      }
    } finally {
      client.close();
    }
  }

  Future<void> _finalizeInstallation() async {
    final httpClient = http.Client();
    final client = RetryClient(httpClient);

    final apiKey = apikey.value.text;

    try {
      var url = urlText.value.text;
      var uri = Uri.tryParse('$url/api/installer/final');
      var response = await client.post(uri!,
          headers: {"X-SpaceUp-Key": apiKey}
      );

      if (response.statusCode == 200) {
        Util.showMessage(context, "Great! You finished the SpaceUp setup!");
        setState(() {
          titleText.value = "Login";
          showProgressBar.value = false;
          showProcess.value = 2;
        });
      } else {
        final msg = response.body;
        Util.showMessage(context, "Error: $msg", durationInSeconds: 5);
      }
    } finally {
      client.close();
    }
  }

  Future<void> getUserSettings() async {
    bool isRememberLogin = await Settings().getBool("rememberLogin", false);
    bool isAutoLogin = await Settings().getBool("autoLogin", false);
    bool manualLogout = await Settings().getBool("manualLogout", false);

    print("Remember login: $isRememberLogin");
    print("Auto login: $isAutoLogin");
    print("Manual logout: $manualLogout ");

    setState(() {
      rememberLogin = isRememberLogin;
      autoLogin = isAutoLogin;
      manuallyLogout = manualLogout;
    });

    if (isRememberLogin) {
      urlText.text = (await Settings().getString("server", ""))!;
      usernameText.text = (await Settings().getString("username", ""))!;
      passwordText.text = (await Settings().getString("password", ""))!;
    }
  }
}

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16.0),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2.0)),
  ),
);

/**
 * Method annotation
 */
class Setup {
  const Setup();
}

const setup = Setup();