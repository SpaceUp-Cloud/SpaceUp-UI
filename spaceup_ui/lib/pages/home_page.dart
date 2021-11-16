import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  ScrollController scrollController = ScrollController();
  var refreshKeyServerVersion = GlobalKey<RefreshIndicatorState>();
  var refreshKeyHostname = GlobalKey<RefreshIndicatorState>();
  var refreshKeyDisk = GlobalKey<RefreshIndicatorState>();
  late Timer _timer;

  var profiles = <String>[];
  var activeProfile = "";
  late String selectedProfile = "http://localhost:9090";

  // Depending on platform the home widget shows x cards per column
  late int maxElementsPerLine;

  // System information
  late Future<String> serverVersion;
  late Future<String> hostname;
  late Future<Disk> disk;

  @override
  void initState() {
    super.initState();
    Util.checkJWT(context);

    setState(() {
      hostname = _getHostname();
      disk = _getDisk();
      serverVersion = _getServerVersion();
    });

    final Util util = Util();
    if (util.isDesktop) {
      maxElementsPerLine = 12;
    } else if (util.isMobile) {
      maxElementsPerLine = 2;
    } else {
      maxElementsPerLine = 2;
    }

    _refreshView();
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    //checkingForBioMetrics().then((value) => _authenticateMe());

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title!),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                height: 100,
                child: DrawerHeader(
                    // TODO: Display SpaceUp Icon
                    decoration: BoxDecoration(color: Colors.teal),
                    child: Text('Menu')),
              ),
              ListTile(
                title: Text("Domains"),
                onTap: () {
                  Get.toNamed(UIData.domainsRoute);
                },
              ),
              ListTile(
                title: Text("Services"),
                onTap: () {
                  Get.toNamed(UIData.servicesRoute);
                },
              ),
              Divider(
                height: 1.0,
              ),
              ListTile(
                title: Text('Settings'),
                onTap: () {
                  Get.toNamed(UIData.settingsRoute);
                },
              ),
              ListTile(
                title: Text('About'),
                onTap: () {
                  Get.back();
                },
              ),
              Divider(
                height: 1.0,
              ),
              ListTile(
                title: Text('Logout'),
                onTap: () {
                  Util.logout(context);
                },
              )
            ],
          ),
        ),
        body: Column(
          children: [
            RefreshIndicator(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                controller: scrollController,
                child: getServerVersionBuilder(),
              ),
              onRefresh: _getServerVersion,
              key: refreshKeyServerVersion,
            ),
            RefreshIndicator(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                controller: scrollController,
                child: getHostnameBuilder(),
              ),
              onRefresh: _getHostname,
              key: refreshKeyHostname,
            ),
            RefreshIndicator(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                controller: scrollController,
                child: getDiskBuilder(),
              ),
              onRefresh: _getDisk,
              key: refreshKeyDisk,
            ),
          ],
        ));
  }

  Card createServerVersionCard(String version) {
    return Card(
        //margin: EdgeInsets.fromLTRB(10.0, 5.0, 0.0, 5.0),
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ListTile(
          leading: Icon(Icons.miscellaneous_services),
          title: Text("Server version: " + version),
        ),
      ],
    ));
  }

  Card createHostnameCard(String hostname) {
    return Card(
        //margin: EdgeInsets.fromLTRB(10.0, 5.0, 0.0, 5.0),
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ListTile(
          leading: Icon(Icons.cloud),
          title: Text("Hostname: " + hostname),
        ),
      ],
    ));
  }

  FutureBuilder<String> getServerVersionBuilder() {
    return FutureBuilder<String>(
        future: serverVersion,
        initialData: "",
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return createServerVersionCard(snapshot.data!);
          } else if (snapshot.hasError) {
            Util.showMessage(context, "${snapshot.error}");
          }

          return Center(
            child: LinearProgressIndicator(),
          );
        });
  }

  FutureBuilder<String> getHostnameBuilder() {
    return FutureBuilder<String>(
        future: hostname,
        initialData: "",
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return createHostnameCard(snapshot.data!);
          } else if (snapshot.hasError) {
            Util.showMessage(context, "${snapshot.error}");
          }

          return Center(
            child: LinearProgressIndicator(),
          );
        });
  }

  FutureBuilder<Disk> getDiskBuilder() {
    return FutureBuilder<Disk>(
        future: disk,
        initialData: Disk(
            availableQuota: 0.0, quota: "", space: "", spacePercentage: 0.0),
        builder: (context, AsyncSnapshot<Disk> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return createDiskCard(snapshot.data!);
          } else if (snapshot.hasError) {
            Util.showMessage(context, "${snapshot.error}");
          }

          return Center(
            child: LinearProgressIndicator(),
          );
        });
  }

  Card createDiskCard(Disk disk) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(5.0),
        child: Column(
          children: [
            Row(
              children: [
                Text("Used:"),
                Card(
                  child: Text("${disk.space} / ${disk.spacePercentage}%"),
                  margin: EdgeInsets.all(5.0),
                  //color: theme.buttonColor,
                )
              ],
            ),
            Row(
              children: [
                Text("Available:"),
                Card(
                  child: Text("${disk.quota} / ${disk.availableQuota}%"),
                  margin: EdgeInsets.all(5.0),
                  //color: theme.buttonColor,
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<String> _getServerVersion() async {
    String serverVersion = "";

    final client = RetryClient(http.Client());
    try {
      final url = await URL().baseUrl;
      final jwt = await Util().getJWT(context);
      var response =
          await client.get(Uri.tryParse('$url/system/version')!, headers: jwt);
      if (response.body.isNotEmpty && response.statusCode == 200) {
        print(response.body);
        serverVersion = response.body;
      }
    } finally {
      client.close();
    }
    return serverVersion;
  }

  Future<String> _getHostname() async {
    String hostname = "";

    final client = RetryClient(http.Client());
    try {
      final url = await URL().baseUrl;
      final jwt = await Util().getJWT(context);
      var response =
          await client.get(Uri.tryParse('$url/system/hostname')!, headers: jwt);
      print(response.body);
      if (response.body.isNotEmpty && response.statusCode == 200) {
        hostname = jsonDecode(response.body)["hostname"];
      }
    } finally {
      client.close();
    }
    return hostname;
  }

  Future<Disk> _getDisk() async {
    Disk disk =
        Disk(space: "", spacePercentage: 0.0, quota: "", availableQuota: 0.0);

    final client = RetryClient(http.Client());
    try {
      final url = await URL().baseUrl;
      final jwt = await Util().getJWT(context);

      var response =
          await client.get(Uri.tryParse('$url/system/disk')!, headers: jwt);
      print(response.body);
      if (response.body.isNotEmpty && response.statusCode == 200) {
        disk = Disk.fromJson(jsonDecode(response.body));
      }
    } finally {
      client.close();
    }

    return disk;
  }

  Future<void> _refreshView() async {
    bool refreshView = await Settings().getBool("refreshView", true);

    if (refreshView) {
      print("Initialize view refresher");
      _timer = Timer.periodic(Duration(seconds: 5), (timer) {
        setState(() {
          disk = _getDisk();
          serverVersion = _getServerVersion();
        });
      });
    } else {
      try {
        if (_timer.isActive) {
          _timer.cancel();
        }
      } catch (e) {
        print("View refresh timer is not initialized");
      }
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

  Disk(
      {required this.space,
      required this.spacePercentage,
      required this.quota,
      required this.availableQuota});

  factory Disk.fromJson(Map<String, dynamic> json) => _diskFromJson(json);
}

Disk _diskFromJson(Map<String, dynamic> json) {
  return Disk(
      space: json["space"],
      spacePercentage: json["spacePercentage"],
      quota: json["quota"],
      availableQuota: json["availableQuota"]);
}
