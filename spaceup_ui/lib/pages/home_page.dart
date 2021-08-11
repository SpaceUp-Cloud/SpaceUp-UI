import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:shared_preferences_settings/shared_preferences_settings.dart';
import 'package:spaceup_ui/ui_data.dart';
import 'package:spaceup_ui/util.dart';

class HomePage extends StatefulWidget {
  HomePage(this.title) : super();

  final String? title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /*final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _authenticated = false;*/

  var profiles = <String>[];
  var activeProfile = "";
  late String selectedProfile = "http://localhost:9090";

  // Depending on platform the home widget shows x cards per column
  late int maxElementsPerLine;

  // System information
  String hostname = "";
  Disk disk = Disk(
      space: "",
      spacePercentage: 0.0,
      quota: "",
      availableQuota: 0.0
  );


  @override
  void initState() {
    super.initState();
    initHostname();
    initDisk();

    initProfiles();

    final Util util = Util();
    if (util.isDesktop) {
      maxElementsPerLine = 12;
    } else if (util.isMobile) {
      maxElementsPerLine = 2;
    } else {
      maxElementsPerLine = 2;
    }
  }

  void initProfiles() async {
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
    ThemeData theme = Theme.of(context);
    //checkingForBioMetrics().then((value) => _authenticateMe());
    // Get server profiles
    initProfiles();

    return Scaffold(
        appBar: AppBar(
          actions: [
            Container(
              padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
              child: DropdownButton<String>(
                value: selectedProfile,
                onTap: initProfiles,
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
              Divider(height: 1.0,),
              ListTile(
                title: Text('Logout'),
                onTap: () {
                  Util().logout(context);
                },
              )
            ],
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(2.0),
          child: ListView(
            children: [
              Card(
                //margin: EdgeInsets.fromLTRB(10.0, 5.0, 0.0, 5.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ListTile(
                      leading: Icon(Icons.cloud),
                      title: Text("Hostname: " + hostname),
                    ),
                    Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Column(
                        children: [
                          Text("Quota"),
                          Row(
                            children: [
                              Text("Used:"),
                              Card(
                                child: Text("${disk.space} / ${disk.spacePercentage}%"),
                                margin: EdgeInsets.all(5.0),
                                color: theme.buttonColor,
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Text("Available:"),
                              Card(
                                child: Text("${disk.quota} / ${disk.availableQuota}%"),
                                margin: EdgeInsets.all(5.0),
                                color: theme.buttonColor,
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                )
              ),
            ])
          ),
        );
  }

  Future<void> initHostname() async {
    final client = RetryClient(http.Client());
    
    try {
      final url = await URL().baseUrl;
      final jwt = await Util().getJWT();
      
      var response = await client.get(
          Uri.tryParse('$url/system/hostname')!,
          headers: jwt);
      print(response.body);
      if(response.body.isNotEmpty && response.statusCode == 200) {
        this.hostname = jsonDecode(response.body)["hostname"];
      }
    } finally {
      client.close();
    }
  }

  Future<void> initDisk() async {
    final client = RetryClient(http.Client());

    try {
      final url = await URL().baseUrl;
      final jwt = await Util().getJWT();

      var response = await client.get(
          Uri.tryParse('$url/system/disk')!,
          headers: jwt);
      print(response.body);
      if(response.body.isNotEmpty && response.statusCode == 200) {
        this.disk = Disk.fromJson(jsonDecode(response.body));
      }
    } finally {
      client.close();
    }
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

class Disk {
  String space;
  double spacePercentage;
  String quota;
  double availableQuota;

  Disk({
    required this.space,
    required this.spacePercentage,
    required this.quota,
    required this.availableQuota
  });
  
  factory Disk.fromJson(Map<String, dynamic> json) => _diskFromJson(json);
}

Disk _diskFromJson(Map<String, dynamic> json) {
  return Disk(
      space: json["space"], 
      spacePercentage: json["spacePercentage"],
      quota: json["quota"], 
      availableQuota: json["availableQuota"]
    );
}
