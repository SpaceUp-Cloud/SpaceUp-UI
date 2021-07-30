import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:local_auth/local_auth.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/pages/domain_page.dart';
import 'package:spaceup_ui/pages/services_page.dart';
import 'package:spaceup_ui/pages/settings_page.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';

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
          primarySwatch: Colors.deepOrange
      ),
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
          case '/services':
            {
              return PageTransition(
                  child: ServicesPageStarter(),
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
  /*final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _authenticated = false;*/

  var profiles = <String>[];
  var activeProfile = "";
  late String selectedProfile = "http://localhost:9090";

  // Depending on platform the home widget shows x cards per column
  late int maxElementsPerLine;

  @override
  void initState() {
    super.initState();
    final Util util = Util();
    if (util.isDesktop) {
      maxElementsPerLine = 12;
    } else if (util.isMobile) {
      maxElementsPerLine = 2;
    } else {
      maxElementsPerLine = 2;
    }
  }

  void getProfiles() async {
    var savedProfiles = await Settings()
        .getString("profiles", "http://localhost:9090");
    profiles = savedProfiles.replaceAll(" ", "").split(";");
    activeProfile = await Settings()
        .getString("profile_active", "http://localhost:9090");

    setState(() {
      if(activeProfile.isEmpty && !profiles.contains(activeProfile)) {
        String defaultProfile = "http://localhost:9090";
        Settings().save("profiles", defaultProfile);
        Settings().save("profile_active", defaultProfile);
        profiles.add(defaultProfile);
        activeProfile = defaultProfile;
      }

      selectedProfile = activeProfile != "" && profiles.contains(activeProfile)
          ? activeProfile : profiles.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    //checkingForBioMetrics().then((value) => _authenticateMe());

    // Get server profiles
    getProfiles();

    return Scaffold(
        appBar: AppBar(
          actions: [
            Container(
              padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
              child: DropdownButton<String>(
                value: selectedProfile,
                onTap: getProfiles,
                onChanged: (String? newProfile) {
                  setState(() {
                    selectedProfile = newProfile!;
                    Settings().save("profile_active", selectedProfile);
                  });
                },
                items: profiles.map<DropdownMenuItem<String>>((String e) {
                  return DropdownMenuItem<String>(
                    value: e,
                    child: Text(e),
                  );
                }).toList(),
              ),

            ),
          ],
          title: Text(widget.title!),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                // TODO: Display SpaceUp Icon
                decoration: BoxDecoration(color: Colors.teal),
                child: Text('Menu')
              ),

              ListTile(
                title: Text("Domains"),
                onTap: () {
                  Navigator.pushNamed(context, UIData.domainsRoute);
                },
              ),
              ListTile(
                title: Text("Services"),
                onTap: () {
                  Navigator.pushNamed(context, UIData.servicesRoute);
                },
              ),
              Divider(height: 1.0,),
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
        body: Container(
          child: null /*GridView.count(
            crossAxisCount: maxElementsPerLine,
            scrollDirection: Axis.vertical,
            children: [
              Style().createCard(context, Icons.cloud,
                  "Domains", UIData.domainsRoute,
                  Colors.teal, Colors.white),
              Style().createCard(context, Icons.miscellaneous_services,
                  "Services", UIData.servicesRoute,
                  Colors.teal, Colors.white),
            ],
          ),*/
        ));
  }

  /*
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
  }*/
}
