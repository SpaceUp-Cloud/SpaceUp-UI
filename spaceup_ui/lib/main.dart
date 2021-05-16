import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:io' show Platform, sleep;
import 'package:page_transition/page_transition.dart';
import 'package:spaceup_ui/domain_page.dart';
import 'package:spaceup_ui/settings_page.dart';
import 'package:spaceup_ui/ui_data.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  MyApp() : super();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpaceUp Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.teal,
          primarySwatch: Colors.deepOrange),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal.shade800,
        accentColor: Colors.teal.shade600,
        primaryColorDark: Colors.white,
        primarySwatch: Colors.teal,
      ),
      home: MyHomePage("Home"),
      initialRoute: null,
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/domains':
            {
              return PageTransition(
                  child: DomainPageStarter(),
                  type: PageTransitionType.leftToRight);
            }
          case '/settings':
            {
              return PageTransition(
                  child: SettingsPageStarter(),
                  type: PageTransitionType.leftToRight);
            }
          default:
            {
              return PageTransition(
                  child: MyHomePage("Home"),
                  type: PageTransitionType.leftToRight);
            }
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(this.title) : super();

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _authenticated = false;

  // Depending on platform the home widget shows x cards per column
  late int maxElementsPerLine;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isLinux) {
      maxElementsPerLine = 8;
    } else if (Platform.isAndroid || Platform.isIOS) {
      maxElementsPerLine = 2;
    } else {
      maxElementsPerLine = 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    //checkingForBioMetrics().then((value) => _authenticateMe());

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title!),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                  // TODO: Display SpaceUp Icon
                  decoration: BoxDecoration(color: Colors.teal),
                  child: Text('Menu')),
              ListTile(
                title: Text('Settings'),
                onTap: () {
                  Navigator.pushNamed(context, UIData.settingsRoute);
                },
              ),
              ListTile(
                title: Text('About'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        body: Center(
          child: GridView.count(
            crossAxisCount: maxElementsPerLine,
            scrollDirection: Axis.vertical,
            children: [
              _createCard(
                  "Domains", UIData.domainsRoute, Colors.teal, Colors.white),
            ],
          ),
        ));
  }

  InkWell _createCard(
      String cardTitle, String path, MaterialColor bgColor, Color fontColor) {
    return InkWell(
        onTap: () {
          Navigator.pushNamed(context, path);
        },
        child: Card(
          semanticContainer: true,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 4,
          margin: EdgeInsets.all(10),
          color: bgColor,
          child: Center(
            child: Text(
              cardTitle,
              style: TextStyle(
                  color: fontColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ));
  }

  Future<bool> checkingForBioMetrics() async {
    bool canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
    print(canCheckBiometrics);
    return canCheckBiometrics;
  }

  Future<void> _authenticateMe() async {
    var authenticated = false;
    try {
      authenticated = await _localAuthentication.authenticate(
          biometricOnly: true,
          localizedReason: "Just for SpaceUp users",
          // message for dialog
          useErrorDialogs: true,
          // show error in dialog
          stickyAuth: true);
    } catch (e) {
      print(e);
    }

    setState(() {
      print("Authenticated: $authenticated");
      _authenticated = authenticated;
    });

    if (!mounted) return;
  }
}
